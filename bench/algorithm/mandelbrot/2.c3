module app;
import libc;
import std::io;
import std::hash::md5;
import std::thread;

const int VEC_SIZE = 8;
alias Vec = double[<VEC_SIZE>];

fn char mbrot8(Vec cr, double civ)
{
	Vec ci;
	ci[..] = civ;
	Vec zr, zi, tr, ti, absz;
	Vec tmp;

	for (int i = 0; i < 10; ++i)
	{
		for (int j = 0; j < 5; ++j)
		{
			tmp = zr + zr;
			tmp = tmp * zi;
			zi = tmp + ci;

			tmp = tr - ti;
			zr = tmp + cr;
			tr = zr * zr;
			ti = zi * zi;
		}

		absz = tr + ti;
		bool terminate = true;
		for (int k = 0; k < VEC_SIZE; ++k)
		{
			if (absz[k] <= 4.0)
			{
				terminate = false;
				break;
			}
		}
		if (terminate)
		{
			return 0;
		}
	}

	char accu = 0;
	for (int k = 0; k < VEC_SIZE; ++k)
	{
		if (absz[k] <= 4.0)
		{
			char lhs = (char)0x80;
			accu |= (char)(lhs >> k);
		}
	}
	return accu;
}

fn double init_xloc(int i, double inv)
{
	return (double)i * inv - 1.5;
}

struct ThreadContext
{
	int start_y;
	int end_y;
	int chunk_size;
	double inv;
	Vec* xloc;
	char* pixels;
}

fn int thread_worker(void* arg)
{
	ThreadContext* ctx = (ThreadContext*)arg;
	for (int y = ctx.start_y; y < ctx.end_y; ++y)
	{
		double ci = (double)y * ctx.inv - 1.0;
		for (int x = 0; x < ctx.chunk_size; ++x)
		{
			ctx.pixels[y * ctx.chunk_size + x] = mbrot8(ctx.xloc[x], ci);
		}
	}
	return 0;
}

fn int main(String[] args)
{
	int n = 200;
	if (args.len > 1)
	{
		n = libc::atoi((char*)args[1].ptr);
	}
	int size = (n + VEC_SIZE - 1) / VEC_SIZE * VEC_SIZE;
	int chunk_size = size / VEC_SIZE;
	double inv = 2.0 / (double)size;

	Vec* xloc = (Vec*)libc::malloc((usz)(chunk_size * Vec.sizeof));

	for (int i = 0; i < chunk_size; ++i)
	{
		int offset = i * VEC_SIZE;
		for (int j = 0; j < VEC_SIZE; ++j)
		{
			xloc[i][j] = init_xloc(offset + j, inv);
		}
	}
	libc::printf((ZString)"P4\n%d %d\n", size, size);

	char* pixels = (char*)libc::malloc((usz)((long)size * (long)chunk_size * (long)char.sizeof));

	int num_threads = 16;
	int rows_per_thread = size / num_threads;
	if (rows_per_thread == 0)
	{
		num_threads = 1;
		rows_per_thread = size;
	}

	Thread* threads = (Thread*)libc::malloc((usz)(num_threads * Thread.sizeof));
	ThreadContext* ctxs = (ThreadContext*)libc::malloc((usz)(num_threads * ThreadContext.sizeof));

	for (int i = 0; i < num_threads; ++i)
	{
		ctxs[i].start_y = i * rows_per_thread;
		ctxs[i].end_y = (i == num_threads - 1) ? size : (i + 1) * rows_per_thread;
		ctxs[i].chunk_size = chunk_size;
		ctxs[i].inv = inv;
		ctxs[i].xloc = xloc;
		ctxs[i].pixels = pixels;
		if (catch err = threads[i].create(&thread_worker, &ctxs[i]))
		{
			io::printfn("Thread creation failed: %s", err);
			return 1;
		}
	}

	for (int i = 0; i < num_threads; ++i)
	{
		if (catch err = threads[i].join())
		{
			io::printfn("Thread join failed: %s", err);
			return 1;
		}
	}

	md5::Md5 md5;
	md5.init();

	md5.update(pixels[0:(usz)((long)size * (long)chunk_size)]);

	char[16] output = md5.final();
	for (int i = 0; i < 16; ++i)
	{
		libc::printf((ZString)"%02x", output[i]);
	}
	libc::printf((ZString)"\n");

	libc::free(threads);
	libc::free(ctxs);
	libc::free(xloc);
	libc::free(pixels);

	return 0;
}