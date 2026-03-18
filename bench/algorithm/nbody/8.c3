module app;
import std::math;
import std::io;

const double SOLAR_MASS      = 4f * math::PI * math::PI;
const double DAYS_PER_YEAR   = 365.24f;
const int BODIES_COUNT       = 5;
const int INTERACTIONS_COUNT = BODIES_COUNT * (BODIES_COUNT - 1) / 2;
const int ROUNDED            = INTERACTIONS_COUNT + INTERACTIONS_COUNT % 2;

alias Vec2d = double[<2>];

struct Body
{
	double[3] position;
	double[3] velocity;
	double mass;
}

Body[5] solar_bodies = {
	{ // Sun
	{ 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0 }, SOLAR_MASS },
	{ // Jupiter
		{ 4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01 },
		{
			1.66007664274403694e-03 * DAYS_PER_YEAR,
			7.69901118419740425e-03 * DAYS_PER_YEAR,
			-6.90460016972063023e-05 * DAYS_PER_YEAR
		},
		9.54791938424326609e-04 * SOLAR_MASS
	},
	{ // Saturn
		{ 8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01 },
		{
			-2.76742510726862411e-03 * DAYS_PER_YEAR,
			4.99852801234917238e-03 * DAYS_PER_YEAR,
			2.30417297573763929e-05 * DAYS_PER_YEAR
		},
		2.85885980666130812e-04 * SOLAR_MASS
	},
	{ // Uranus
		{ 1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01 },
		{
			2.96460137564761618e-03 * DAYS_PER_YEAR,
			2.37847173959480950e-03 * DAYS_PER_YEAR,
			-2.96589568540237556e-05 * DAYS_PER_YEAR
		},
		4.36624404335156298e-05 * SOLAR_MASS
	},
	{ // Neptune
		{ 1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01 },
		{
			2.68067772490389322e-03 * DAYS_PER_YEAR,
			1.62824170038242295e-03 * DAYS_PER_YEAR,
			-9.51592254519715870e-05 * DAYS_PER_YEAR
		},
		5.15138902046611451e-05 * SOLAR_MASS
	}
};

double[ROUNDED] pos_delta_x;
double[ROUNDED] pos_delta_y;
double[ROUNDED] pos_delta_z;
double[ROUNDED] magnitudes;

fn void advance(Body[] bodies) @inline
{
	int k = 0;
	for (int i = 0; i < BODIES_COUNT - 1; ++i)
	{
		for (int j = i + 1; j < BODIES_COUNT; ++j, ++k)
		{
			pos_delta_x[k] = bodies[i].position[0] - bodies[j].position[0];
			pos_delta_y[k] = bodies[i].position[1] - bodies[j].position[1];
			pos_delta_z[k] = bodies[i].position[2] - bodies[j].position[2];
		}
	}

	for (int i = 0; i < ROUNDED / 2; ++i)
	{
		Vec2d dx = { pos_delta_x[i * 2], pos_delta_x[i * 2 + 1] };
		Vec2d dy = { pos_delta_y[i * 2], pos_delta_y[i * 2 + 1] };
		Vec2d dz = { pos_delta_z[i * 2], pos_delta_z[i * 2 + 1] };

		Vec2d dist2 = dx * dx + dy * dy + dz * dz;

		Vec2d r = 1.0 / math::sqrt(dist2);
		r = r * (1.5 - 0.5 * dist2 * r * r);
		r = r * (1.5 - 0.5 * dist2 * r * r);

		Vec2d mag = { 0.01, 0.01 };
		mag = mag / dist2 * r;
		magnitudes[i * 2] = mag[0];
		magnitudes[i * 2 + 1] = mag[1];
	}

	k = 0;
	for (int i = 0; i < BODIES_COUNT - 1; ++i)
	{
		for (int j = i + 1; j < BODIES_COUNT; ++j, ++k)
		{
			double im = bodies[i].mass * magnitudes[k];
			double jm = bodies[j].mass * magnitudes[k];
			bodies[i].velocity[0] -= pos_delta_x[k] * jm;
			bodies[i].velocity[1] -= pos_delta_y[k] * jm;
			bodies[i].velocity[2] -= pos_delta_z[k] * jm;
			bodies[j].velocity[0] += pos_delta_x[k] * im;
			bodies[j].velocity[1] += pos_delta_y[k] * im;
			bodies[j].velocity[2] += pos_delta_z[k] * im;
		}
	}

	foreach (&b : bodies)
	{
		b.position[0] += 0.01 * b.velocity[0];
		b.position[1] += 0.01 * b.velocity[1];
		b.position[2] += 0.01 * b.velocity[2];
	}
}

fn void offset_momentum(Body[] bodies)
{
	foreach (&b : bodies)
	{
		bodies[0].velocity[0] -= b.velocity[0] * b.mass / SOLAR_MASS;
		bodies[0].velocity[1] -= b.velocity[1] * b.mass / SOLAR_MASS;
		bodies[0].velocity[2] -= b.velocity[2] * b.mass / SOLAR_MASS;
	}
}

fn void output_energy(Body[] bodies) @inline
{
	double e = 0.0;
	foreach (i, &b : bodies)
	{
		e += 0.5 * b.mass
			* (b.velocity[0] * b.velocity[0] + b.velocity[1] * b.velocity[1] + b.velocity[2] * b.velocity[2]);
		foreach (&b2 : bodies[i + 1..])
		{
			double dx = b.position[0] - b2.position[0];
			double dy = b.position[1] - b2.position[1];
			double dz = b.position[2] - b2.position[2];
			e -= b.mass * b2.mass / math::sqrt(dx * dx + dy * dy + dz * dz);
		}
	}
	io::printfn("%.9f", e);
}

fn int main(String[] args)
{
	int n = 1000;
	if (args.len > 1)
	{
		n = args[1].to_int() ?? 1000;
	}

	Body[] bslice = solar_bodies[..];
	offset_momentum(bslice);
	output_energy(bslice);
	for (int i = n; i-- > 0;)
	{
		advance(bslice);
	}
	output_energy(bslice);

	return 0;
}