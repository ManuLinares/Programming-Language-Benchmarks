module app;
import std::io;
import std::math;
import std::os;
import std::thread;

fn int a(int i, int j) @inline
{
	return (i + j) * (i + j + 1) / 2 + i + 1;
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

struct MultData
{
	double[] v;
	double[] out;
	int n;
	int start;
	int end;
	bool transpose;
}

fn int mult_worker(void* arg)
{
	MultData* data = (MultData*)arg;
	for (int i = data.start; i < data.end; i++)
	{
		double sum = 0;
		for (int j = 0; j < data.n; j++)
		{
			if (data.transpose)
			{
				sum += data.v[j] / a(j, i);
			}
			else
			{
				sum += data.v[j] / a(i, j);
			}
		}
		data.out[i] = sum;
	}
	return 0;
}

fn void mult_parallel(double[] v, double[] out, int n, bool transpose)
{
	int num_threads = (int)os::num_cpu();
	if (n < num_threads * 2)
	{
		MultData data = { v, out, n, 0, n, transpose };
		mult_worker(&data);
		return;
	}

	Thread[] threads = mem::new_array(Thread, num_threads);
	MultData[] datas = mem::new_array(MultData, num_threads);
	defer free(threads);
	defer free(datas);

	int chunk = n / num_threads;
	for (int i = 0; i < num_threads; i++)
	{
		datas[i] = { v, out, n, i * chunk, (i == num_threads - 1) ? n : (i + 1) * chunk, transpose };
		if (catch err = threads[i].create(&mult_worker, &datas[i]))
		{
			io::printfn("Failed to create thread: %s", err);
			os::exit(1);
		}
	}

	for (int i = 0; i < num_threads; i++)
	{
		if (catch err = threads[i].join())
		{
			io::printfn("Failed to join thread: %s", err);
			os::exit(1);
		}
	}
}

double[] tmp;

fn void mult_atav(double[] v, double[] out, int n)
{
	mult_parallel(v, tmp, n, false);
	mult_parallel(tmp, out, n, true);
}

fn int main(String[] args)
{
	int n = 2000;
	if (args.len > 1)
	{
		n = args[1].to_int() ?? 2000;
	}

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