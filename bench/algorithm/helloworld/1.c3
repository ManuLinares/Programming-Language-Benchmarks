module app;
import std::io;

fn int main(String[] args)
{
	if (args.len < 2)
	{
		io::print("Hello world!");
	}
	else
	{
		io::printf("Hello world %s!", args[1]);
	}
	return 0;
}