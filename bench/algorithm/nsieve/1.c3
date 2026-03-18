module app;
import std::io;

fn void nsieve(int m)
{
	bool[] flags = mem::new_array(bool, m);
	defer free(flags);

	flags[..] = true;

	uint count;
	for (uint i = 2; i < (uint)m; ++i)
	{
		if (flags[i])
		{
			++count;
			for (uint j = i << 1; j < (uint)m; j += i)
			{
				flags[j] = false;
			}
		}
	}

	io::printfn("Primes up to %8d %8d", m, count);
}

fn int main(String[] args)
{
	int m = 9;
	if (args.len > 1)
	{
		m = args[1].to_int() ?? 9;
	}
	for (int i = 0; i < 3; i++)
	{
		nsieve(10000 << (m - i));
	}
	return 0;
}