module app;
import libc;
import std::io;
import std::collections::map;

const usz INITIAL_HASH_TABLE_SIZE = 16;

alias Map = HashMap{long, int};

macro char @code_for_nucleotide(nucleotide)
{
	return " \x00 \x01\x03  \x02"[nucleotide & 0b111];
}

macro char @nucleotide_for_code(code)
{
	return "ACGT"[code & 0b11];
}

struct Element
{
	long key;
	int value;
}

fn int element_compare(void* left, void* right)
{
	Element* l = (Element*)left;
	Element* r = (Element*)right;
	if (l.value < r.value) return 1;
	if (l.value > r.value) return -1;
	if (l.key > r.key) return 1;
	return -1;
}

fn void generate_frequencies(char* polynucleotide, long len, long desired_len)
{
	Map table;
	table.init(mem, (uint)INITIAL_HASH_TABLE_SIZE);

	long code = 0;
	for (long i = 0; i < len; i++)
	{
		long mask = ((long)1 << (2 * (uint)desired_len)) - 1;
		code = ((code << 2) & mask) | (long)polynucleotide[i];
		if (i >= desired_len - 1)
		{
			int* val = table.get_or_create_ref(code);
			*val += 1;
		}
	}

	long elements_array_size = (long)table.len();
	Element* elements_array = (Element*)libc::malloc((usz)(elements_array_size * Element.sizeof));

	long j = 0;
	table.@each(; k, v)
	{
		elements_array[j].key = k;
		elements_array[j].value = v;
		j++;
	};
	table.free();

	libc::qsort(elements_array, (usz)elements_array_size, (usz)Element.sizeof, &element_compare);

	long total_count = 0;
	for (long i = 0; i < elements_array_size; i++)
	{
		total_count += elements_array[i].value;
	}

	for (long i = 0; i < elements_array_size; i++)
	{
		char[32] oligo;
		long key = elements_array[i].key;
		for (long oligo_idx = desired_len - 1; oligo_idx >= 0; oligo_idx--)
		{
			oligo[oligo_idx] = @nucleotide_for_code((char)key);
			key >>= 2;
		}
		oligo[desired_len] = '\0';
		io::printfn("%s %.3f", (ZString)&oligo[0], 100.0 * (double)elements_array[i].value / (double)total_count);
	}
	io::printn();
	libc::free(elements_array);
}

fn void generate_count(char* polynucleotide, long len, String oligo_str)
{
	ZString oligo = oligo_str.zstr_tcopy();
	long oligo_len = (long)libc::strlen(oligo);
	Map table;
	table.init(mem, (uint)INITIAL_HASH_TABLE_SIZE);

	long code = 0;
	for (long i = 0; i < len; i++)
	{
		long mask = ((long)1 << (2 * (uint)oligo_len)) - 1;
		code = ((code << 2) & mask) | (long)polynucleotide[i];
		if (i >= oligo_len)
		{
			int* val = table.get_or_create_ref(code);
			*val += 1;
		}
	}

	code = 0;
	for (long i = 0; i < oligo_len; i++)
	{
		code = (code << 2) | (long)@code_for_nucleotide((char)oligo_str[i]);
	}

	int count = table[code] ?? 0;
	io::printfn("%d\t%s", count, oligo_str);
	table.free();
}

fn int main(String[] args)
{
	char[4096] buffer;
	void* input_file = null;
	if (args.len > 1)
	{
		input_file = libc::fopen((ZString)args[1], "r");
	}
	else
	{
		input_file = libc::stdin();
	}

	if (input_file == null) return 1;

	while (libc::fgets(&buffer[0], 4096, input_file) != null && libc::memcmp((ZString)">THREE", &buffer[0], 6) != 0)
	{
	}

	long capacity = 65536;
	long len = 0;
	char* polynucleotide = (char*)libc::malloc((usz)capacity);

	while (libc::fgets(&buffer[0], 4096, input_file) != null && buffer[0] != '>')
	{
		for (long i = 0; buffer[i] != '\0'; i++)
		{
			if (buffer[i] != '\n' && buffer[i] != '\r')
			{
				polynucleotide[len++] = @code_for_nucleotide(buffer[i]);
			}
		}
		if (capacity - len < 4096)
		{
			capacity *= 2;
			polynucleotide = (char*)libc::realloc(polynucleotide, (usz)capacity);
		}
	}
	polynucleotide = (char*)libc::realloc(polynucleotide, (usz)len);

	generate_frequencies(polynucleotide, len, 1);
	generate_frequencies(polynucleotide, len, 2);
	generate_count(polynucleotide, len, "GGT");
	generate_count(polynucleotide, len, "GGTA");
	generate_count(polynucleotide, len, "GGTATT");
	generate_count(polynucleotide, len, "GGTATTTTAATT");
	generate_count(polynucleotide, len, "GGTATTTTAATTTATAGT");

	if (args.len > 1) libc::fclose(input_file);
	libc::free(polynucleotide);
	return 0;
}