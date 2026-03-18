module app;
import std::math;
import std::io;
import libc;

const double SOLAR_MASS    = 4f * math::PI * math::PI;
const double DAYS_PER_YEAR = 365.24f;

alias Vec3 = double[<3>];

struct Planet
{
	Vec3 pos;
	Vec3 v;
	double mass;
}

Planet[5] bodies = {
	{ /* sun */ { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0 }, SOLAR_MASS },
	{ /* jupiter */
		{ 4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01 },
		{
			1.66007664274403694e-03 * DAYS_PER_YEAR,
			7.69901118419740425e-03 * DAYS_PER_YEAR,
			-6.90460016972063023e-05 * DAYS_PER_YEAR
		},
		9.54791938424326609e-04 * SOLAR_MASS
	},
	{ /* saturn */
		{ 8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01 },
		{
			-2.76742510726862411e-03 * DAYS_PER_YEAR,
			4.99852801234917238e-03 * DAYS_PER_YEAR,
			2.30417297573763929e-05 * DAYS_PER_YEAR
		},
		2.85885980666130812e-04 * SOLAR_MASS
	},
	{ /* uranus */
		{ 1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01 },
		{
			2.96460137564761618e-03 * DAYS_PER_YEAR,
			2.37847173959480950e-03 * DAYS_PER_YEAR,
			-2.96589568540237556e-05 * DAYS_PER_YEAR
		},
		4.36624404335156298e-05 * SOLAR_MASS
	},
	{ /* neptune */
		{ 1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01 },
		{
			2.68067772490389322e-03 * DAYS_PER_YEAR,
			1.62824170038242295e-03 * DAYS_PER_YEAR,
			-9.51592254519715870e-05 * DAYS_PER_YEAR
		},
		5.15138902046611451e-05 * SOLAR_MASS
	}
};

fn void advance(Planet[] bptr) @inline
{
	foreach (i, &b : bptr)
	{
		foreach (&b2 : bptr[i + 1..])
		{
			Vec3 d = b.pos - b2.pos;
			double dist2 = d.dot(d);
			double mag = 1.0 / (dist2 * math::sqrt(dist2));
			b.v -= d * (b2.mass * mag);
			b2.v += d * (b.mass * mag);
		}
	}
	foreach (&b : bptr)
	{
		b.pos += b.v;
	}
}

fn double energy(Planet[] bptr) @inline
{
	double e = 0.0;
	foreach (i, &b : bptr)
	{
		e += 0.5 * b.mass * b.v.dot(b.v);
		foreach (&b2 : bptr[i + 1..])
		{
			double dist = b.pos.distance(b2.pos);
			e -= (b.mass * b2.mass) / dist;
		}
	}
	return e;
}

fn void offset_momentum(Planet[] bptr)
{
	Vec3 p;
	foreach (&b : bptr)
	{
		p += b.v * b.mass;
	}
	bptr[0].v = -p / SOLAR_MASS;
}

const double DT       = 1e-2;
const double RECIP_DT = 1.0 / DT;

fn void scale_bodies(Planet[] bptr, double scale)
{
	foreach (&b : bptr)
	{
		b.mass *= scale * scale;
		b.v *= scale;
	}
}

fn int main(String[] args)
{
	int n = 50000000;
	if (args.len > 1)
	{
		n = args[1].to_int() ?? 50000000;
	}

	Planet[] bslice = bodies[..];
	offset_momentum(bslice);
	io::printfn("%.9f", energy(bslice));
	scale_bodies(bslice, DT);
	for (int i = 1; i <= n; i++)
	{
		advance(bslice);
	}
	scale_bodies(bslice, RECIP_DT);
	io::printfn("%.9f", energy(bslice));

	return 0;
}