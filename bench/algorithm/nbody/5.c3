module app;
import std::math;
import std::io;

const double SOLAR_MASS    = 4f * math::PI * math::PI;
const double DAYS_PER_YEAR = 365.24f;

alias Vec2d = double[<2>];

// Each body stores xy, z0 (z + padding), vxy, vz0, massmass as Vec2d vectors.
// This mirrors the SIMD layout of nbody/5.c.
struct Planet
{
	Vec2d xy;
	Vec2d z0; // [z, 0]
	Vec2d vxy;
	Vec2d vz0; // [vz, 0]
	Vec2d massmass;
}

Planet[5] bodies = {
	{ /* sun */ { 0.0, 0.0 }, { 0.0, 0.0 }, { 0.0, 0.0 }, { 0.0, 0.0 }, { SOLAR_MASS, SOLAR_MASS } },
	{ /* jupiter */
		{ 4.84143144246472090e+00, -1.16032004402742839e+00 },
		{ -1.03622044471123109e-01, 0.0 },
		{ 1.66007664274403694e-03 * DAYS_PER_YEAR, 7.69901118419740425e-03 * DAYS_PER_YEAR },
		{ -6.90460016972063023e-05 * DAYS_PER_YEAR, 0.0 },
		{ 9.54791938424326609e-04 * SOLAR_MASS, 9.54791938424326609e-04 * SOLAR_MASS }
	},
	{ /* saturn */
		{ 8.34336671824457987e+00, 4.12479856412430479e+00 },
		{ -4.03523417114321381e-01, 0.0 },
		{ -2.76742510726862411e-03 * DAYS_PER_YEAR, 4.99852801234917238e-03 * DAYS_PER_YEAR },
		{ 2.30417297573763929e-05 * DAYS_PER_YEAR, 0.0 },
		{ 2.85885980666130812e-04 * SOLAR_MASS, 2.85885980666130812e-04 * SOLAR_MASS }
	},
	{ /* uranus */
		{ 1.28943695621391310e+01, -1.51111514016986312e+01 },
		{ -2.23307578892655734e-01, 0.0 },
		{ 2.96460137564761618e-03 * DAYS_PER_YEAR, 2.37847173959480950e-03 * DAYS_PER_YEAR },
		{ -2.96589568540237556e-05 * DAYS_PER_YEAR, 0.0 },
		{ 4.36624404335156298e-05 * SOLAR_MASS, 4.36624404335156298e-05 * SOLAR_MASS }
	},
	{ /* neptune */
		{ 1.53796971148509165e+01, -2.59193146099879641e+01 },
		{ 1.79258772950371181e-01, 0.0 },
		{ 2.68067772490389322e-03 * DAYS_PER_YEAR, 1.62824170038242295e-03 * DAYS_PER_YEAR },
		{ -9.51592254519715870e-05 * DAYS_PER_YEAR, 0.0 },
		{ 5.15138902046611451e-05 * SOLAR_MASS, 5.15138902046611451e-05 * SOLAR_MASS }
	}
};

const Vec2d DT = { 0.01, 0.01 };

fn void advance(int n, Planet[] bptr)
{
	for (int k = 1; k <= n; ++k)
	{
		foreach (i, &b : bptr)
		{
			foreach (&b2 : bptr[i + 1..])
			{
				Vec2d dxy = b.xy - b2.xy;
				Vec2d dz0 = b.z0 - b2.z0;
				// dist2 = dx*dx + dy*dy + dz*dz (horizontal add via .sum())
				double dist2 = (dxy * dxy).sum() + (dz0 * dz0).sum();
				double mag = 0.01 / (math::sqrt(dist2) * dist2);
				Vec2d magv = { mag, mag };
				dxy *= magv;
				dz0 *= magv;
				b.vxy -= dxy * b2.massmass;
				b.vz0 -= dz0 * b2.massmass;
				b2.vxy += dxy * b.massmass;
				b2.vz0 += dz0 * b.massmass;
			}
		}
		foreach (&b : bptr)
		{
			b.xy += DT * b.vxy;
			b.z0 += DT * b.vz0;
		}
	}
}

fn double energy(Planet[] bptr)
{
	double e = 0.0;
	foreach (i, &b : bptr)
	{
		// KE: 0.5 * mass * (vx*vx + vy*vy + vz*vz)
		double ke = (b.massmass * (b.vxy * b.vxy)).sum() + (b.massmass * (b.vz0 * b.vz0)).sum();
		e += 0.5 * ke;
		foreach (&b2 : bptr[i + 1..])
		{
			Vec2d dxy = b.xy - b2.xy;
			Vec2d dz0 = b.z0 - b2.z0;
			double dist2 = (dxy * dxy).sum() + (dz0 * dz0).sum();
			double dist = math::sqrt(dist2);
			// PE: -(mass_b * mass_b2) / dist — massmass[0] is mass
			e -= (b.massmass * b2.massmass)[0] / dist;
		}
	}
	return e;
}

fn void offset_momentum(Planet[] bptr)
{
	Vec2d pxy;
	Vec2d pz0;
	foreach (&b : bptr)
	{
		pxy += b.vxy * b.massmass;
		pz0 += b.vz0 * b.massmass;
	}
	bptr[0].vxy = -pxy / SOLAR_MASS;
	bptr[0].vz0 = -pz0 / SOLAR_MASS;
}

fn int main(String[] args)
{
	int n = 1000;
	if (args.len > 1)
	{
		n = args[1].to_int() ?? 1000;
	}

	Planet[] bslice = bodies[..];
	offset_momentum(bslice);
	io::printfn("%.9f", energy(bslice));
	advance(n, bslice);
	io::printfn("%.9f", energy(bslice));

	return 0;
}