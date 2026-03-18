module app;
import std::io;
import std::math;
import std::os;
import std::thread;

alias Vec2d = double[<2>];

fn double a_fn(int i, int j) @inline
{
	return (double)((i + j) * (i + j + 1) / 2 + i + 1);
}

struct ThreadParam
{
	double[] v;
	double[] out;
	int n;
	int start_idx;
	int end_idx;
	bool transpose;
}

fn int thread_worker(void* arg)
{
	ThreadParam* data = (ThreadParam*)arg;
	for (int i = data.start_idx; i < data.end_idx; i++)
	{
		double sum_val = 0;
		for (int j = 0; j < data.n; j += 2)
		{
			Vec2d b = { data.v[j], data.v[j + 1] };
			Vec2d a;
			if (data.transpose)
			{
				a = { a_fn(j, i), a_fn(j + 1, i) };
			}
			else
			{
				a = { a_fn(i, j), a_fn(i, j + 1) };
			}
			Vec2d res = b / a;
			sum_val += res[0] + res[1];
		}
		data.out[i] = sum_val;
	}
	return 0;
}

double[] tmp;

fn void execute_parallel(double[] v, double[] out, int n, bool transpose)
{
	int num_threads = (int)os::num_cpu();

	Thread[] threads = mem::new_array(Thread, num_threads);
	ThreadParam[] datas = mem::new_array(ThreadParam, num_threads);
	defer free(threads);
	defer free(datas);

	int chunk = (n + num_threads - 1) / num_threads;
	int spawned = 0;
	for (int i = 0; i < num_threads; i++)
	{
		datas[i] = { v, out, n, i * chunk, (i + 1) * chunk, transpose };
		if (datas[i].start_idx >= n) break;
		if (datas[i].end_idx > n) datas[i].end_idx = n;

		if (catch err = threads[i].create(&thread_worker, &datas[i]))
		{
			io::printfn("Thread error: %s", err);
			os::exit(1);
		}
		spawned++;
	}

	for (int i = 0; i < spawned; i++)
	{
		threads[i].join()!!;
	}
}

fn void mult_atav(double[] v, double[] out, int n)
{
	execute_parallel(v, tmp, n, false);
	execute_parallel(tmp, out, n, true);
}

fn double dot(double[] v, double[] u)
{
	double sum = 0;
	for (uint i = 0; i < v.len; i++)
	{
		sum += v[i] * u[i];
	}
	return sum;
}

fn int main(String[] args)
{
	int n = 2000;
	if (args.len > 1)
	{
		n = args[1].to_int() ?? 2000;
	}
	if (n & 1) n++;

	double[] u = mem::new_array(double, n);
	double[] v = mem::new_array(double, n);
	tmp = mem::new_array(double, n);
	defer free(u);
	defer free(v);
	defer free(tmp);

	for (int i = 0; i < n; i++)
	{
		u[i] = 1.0;
	}

	for (int i = 0; i < 10; i++)
	{
		mult_atav(u, v, n);
		mult_atav(v, u, n);
	}

	io::printfn("%.9f", math::sqrt(dot(u, v) / dot(v, v)));

	return 0;
}