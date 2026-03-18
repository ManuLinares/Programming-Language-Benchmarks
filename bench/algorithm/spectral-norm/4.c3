module app;
import std::io;
import std::math;
import std::os;
import std::thread;

alias Vec2d = double[<2>];

fn double eval_a(int i, int j) @inline
{
	return 1.0 / (double)((((i + j) * (i + j + 1)) >> 1) + i + 1);
}

fn Vec2d eval_a_i(int i, int j) @inline
{
	double d1 = (double)((((i + j) * (i + j + 1)) >> 1) + i + 1);
	double d2 = (double)((((i + 1 + j) * (i + 1 + j + 1)) >> 1) + (i + 1) + 1);
	return { 1.0 / d1, 1.0 / d2 };
}

fn Vec2d eval_a_j(int i, int j) @inline
{
	double d1 = (double)((((i + j) * (i + j + 1)) >> 1) + i + 1);
	double d2 = (double)((((i + j + 1) * (i + j + 1 + 1)) >> 1) + i + 1);
	return { 1.0 / d1, 1.0 / d2 };
}

struct MultData
{
	double[] u;
	double[] tmp;
	double[] v;
	int n;
	int r_begin;
	int r_end;
	bool transpose;
}

fn int thread_worker(void* arg)
{
	MultData* p = (MultData*)arg;
	int n2 = p.n / 2;

	if (p.transpose)
	{
		// eval_At_times_u
		for (int i = p.r_begin; i < p.r_end; i++)
		{
			Vec2d sum = { 0, 0 };
			for (int j = 0; j < n2; j++)
			{
				Vec2d u2 = { p.tmp[j * 2], p.tmp[j * 2 + 1] };
				sum += u2 * eval_a_i(j * 2, i);
			}
			p.v[i] = sum[0] + sum[1];
			if (p.n & 1)
			{
				int j = p.n - 1;
				p.v[i] += eval_a(j, i) * p.tmp[j];
			}
		}
	}
	else
	{
		// eval_A_times_u
		for (int i = p.r_begin; i < p.r_end; i++)
		{
			Vec2d sum = { 0, 0 };
			for (int j = 0; j < n2; j++)
			{
				Vec2d u2 = { p.u[j * 2], p.u[j * 2 + 1] };
				sum += u2 * eval_a_j(i, j * 2);
			}
			p.tmp[i] = sum[0] + sum[1];
			if (p.n & 1)
			{
				int j = p.n - 1;
				p.tmp[i] += eval_a(i, j) * p.u[j];
			}
		}
	}
	return 0;
}

fn void execute_parallel(MultData* base, int num_threads)
{
	Thread[] threads = mem::new_array(Thread, num_threads);
	MultData[] datas = mem::new_array(MultData, num_threads);
	defer free(threads);
	defer free(datas);

	int chunk = base.n / num_threads;
	for (int i = 0; i < num_threads; i++)
	{
		datas[i] = *base;
		datas[i].r_begin = i * chunk;
		datas[i].r_end = (i == num_threads - 1) ? base.n : (i + 1) * chunk;
		if (catch err = threads[i].create(&thread_worker, &datas[i]))
		{
			io::printfn("Failed to create thread: %s", err);
			os::exit(1);
		}
	}

	for (int i = 0; i < num_threads; i++)
	{
		threads[i].join()!!;
	}
}

fn void mult_atav(double[] u, double[] tmp, double[] v, int n, int num_threads)
{
	MultData data;
	data.u = u;
	data.tmp = tmp;
	data.v = v;
	data.n = n;

	// mult_Av
	data.transpose = false;
	execute_parallel(&data, num_threads);

	// mult_Atv
	data.transpose = true;
	execute_parallel(&data, num_threads);
}

fn int main(String[] args)
{
	int n = 2000;
	if (args.len > 1)
	{
		n = args[1].to_int() ?? 2000;
	}

	int num_threads = (int)os::num_cpu();

	double[] u = mem::new_array(double, n);
	double[] tmp = mem::new_array(double, n);
	double[] v = mem::new_array(double, n);
	defer free(u);
	defer free(v);
	defer free(tmp);

	for (int i = 0; i < n; i++)
	{
		u[i] = 1.0;
	}

	for (int ite = 0; ite < 10; ite++)
	{
		mult_atav(u, tmp, v, n, num_threads);
		mult_atav(v, tmp, u, n, num_threads);
	}

	double vbv = 0;
	double vv = 0;
	for (int i = 0; i < n; i++)
	{
		vv += v[i] * v[i];
		vbv += u[i] * v[i];
	}

	io::printfn("%.9f", math::sqrt(vbv / vv));

	return 0;
}