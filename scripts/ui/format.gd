class_name Format

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static func num(n: float) -> String:
	if not is_finite(n):
		return "∞"
	var a := absf(n)
	if a < 1000.0:
		return str(int(n)) if n == floor(n) else "%.2f" % n
	var tier := int(floor(log(a) / log(10.0) / 3.0))
	if tier < SUFFIXES.size():
		return "%.2f%s" % [n / pow(10.0, tier * 3), SUFFIXES[tier]]
	return "%.2e" % n

static func rate(n: float) -> String:
	return num(n) + "/сек"
