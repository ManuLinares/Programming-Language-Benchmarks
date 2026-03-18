module app;
import libc;
import std::io;
import std::hash::md5;

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

	for (int y = 0; y < size; ++y)
	{
		double ci = (double)y * inv - 1.0;
		for (int x = 0; x < chunk_size; ++x)
		{
			pixels[y * chunk_size + x] = mbrot8(xloc[x], ci);
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

	return 0;
}