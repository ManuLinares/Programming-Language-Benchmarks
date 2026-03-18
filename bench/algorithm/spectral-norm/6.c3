module app;

import std::io, std::math, std::os, std::thread;

alias Vec4d = double[<4>];

fn Vec4d eval_a(int i_fixed, int j_start) @inline
{
	double d0 = (double)((((i_fixed + j_start + 0) * (i_fixed + j_start + 0 + 1)) >> 1) + i_fixed + 1);
	double d1 = (double)((((i_fixed + j_start + 1) * (i_fixed + j_start + 1 + 1)) >> 1) + i_fixed + 1);
	double d2 = (double)((((i_fixed + j_start + 2) * (i_fixed + j_start + 2 + 1)) >> 1) + i_fixed + 1);
	double d3 = (double)((((i_fixed + j_start + 3) * (i_fixed + j_start + 3 + 1)) >> 1) + i_fixed + 1);
	return { 1.0 / d0, 1.0 / d1, 1.0 / d2, 1.0 / d3 };
}

fn Vec4d eval_a_t(int i_start, int j_fixed) @inline
{
	double d0 = (double)((((i_start + 0 + j_fixed) * (i_start + 0 + j_fixed + 1)) >> 1) + j_fixed + 1);
	double d1 = (double)((((i_start + 1 + j_fixed) * (i_start + 1 + j_fixed + 1)) >> 1) + j_fixed + 1);
	double d2 = (double)((((i_start + 2 + j_fixed) * (i_start + 2 + j_fixed + 1)) >> 1) + j_fixed + 1);
	double d3 = (double)((((i_start + 3 + j_fixed) * (i_start + 3 + j_fixed + 1)) >> 1) + j_fixed + 1);
	return { 1.0 / d0, 1.0 / d1, 1.0 / d2, 1.0 / d3 };
}

struct MultData
{
	Vec4d[] u, v;
	int n, r_begin_block, r_end_block;
	bool transpose;
}

fn int mult_worker(void* arg)
{
	any a = any_make(arg, MultData.typeid);
	if (try p = anycast(a, MultData))
	{
		int n = p.n;
		if (p.transpose)
		{
			for (int i = p.r_begin_block; i < p.r_end_block; i++)
			{
				Vec4d row_sums = { 0, 0, 0, 0 };
				for (int k = 0; k < p.u.len; k++)
				{
					Vec4d u_chunk = p.u[k];
					row_sums += u_chunk[0] * eval_a_t(i * 4, k * 4 + 0);
					row_sums += u_chunk[1] * eval_a_t(i * 4, k * 4 + 1);
					row_sums += u_chunk[2] * eval_a_t(i * 4, k * 4 + 2);
					row_sums += u_chunk[3] * eval_a_t(i * 4, k * 4 + 3);
				}
				p.v[i] = row_sums;
			}
		}
		else
		{
			int r_start = p.r_begin_block * 4;
			int r_end = p.r_end_block * 4;
			for (int i = r_start; i < r_end; i++)
			{
				if (i >= n)
				{
					break;
				}
				double row_sum = 0;
				for (int j = 0; j < p.u.len; j++)
				{
					row_sum += (p.u[j] * eval_a(i, j * 4)).sum();
				}
				p.v[i / 4][i % 4] = row_sum;
			}
		}
	}
	return 0;
}

fn void execute_parallel(Vec4d[] u, Vec4d[] v, int n, bool transpose)
{
	int nthreads = os::num_cpu();
	Thread[] threads = mem::new_array(Thread, nthreads);
	MultData[] datas = mem::new_array(MultData, nthreads);
	defer
	{
		free(threads);
		free(datas);
	}

	int total_blocks = u.len;
	int chunk = (total_blocks + nthreads - 1) / nthreads;

	int spawned = 0;
	for (int i = 0; i < nthreads; i++)
	{
		datas[i] = { u, v, n, i * chunk, math::min((i + 1) * chunk, total_blocks), transpose };
		if (datas[i].r_begin_block >= total_blocks) break;
		threads[i].create(&mult_worker, &datas[i])!!;
		spawned++;
	}
	for (int i = 0; i < spawned; i++) threads[i].join()!!;
}

fn double dot(Vec4d[] v, Vec4d[] u, int n)
{
	Vec4d sum4 = { 0, 0, 0, 0 };
	for (int i = 0; i < v.len; i++) sum4 += v[i] * u[i];
	return sum4.sum();
}

fn int main(String[] args)
{
	int n = 2000;
	if (args.len > 1) n = args[1].to_int() ?? 2000;

	int n_blocks = (n + 3) / 4;
	Vec4d[] u = mem::new_array_aligned(Vec4d, n_blocks);
	Vec4d[] v = mem::new_array_aligned(Vec4d, n_blocks);
	Vec4d[] tmp = mem::new_array_aligned(Vec4d, n_blocks);
	defer
	{
		free(u);
		free(v);
		free(tmp);
	}

	Vec4d ones = { 1, 1, 1, 1 };
	for (int i = 0; i < n_blocks; i++) u[i] = ones;

	if (n % 4 != 0)
	{
		for (int i = n % 4; i < 4; i++) u[n_blocks - 1][i] = 0.0;
	}

	for (int i = 0; i < 10; i++)
	{
		execute_parallel(u, tmp, n, false);
		execute_parallel(tmp, v, n, true);
		execute_parallel(v, tmp, n, false);
		execute_parallel(tmp, u, n, true);
	}

	io::printfn("%.9f", math::sqrt(dot(u, v, n) / dot(v, v, n)));
	return 0;
}