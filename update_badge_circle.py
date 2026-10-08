import os

chart_path = r"C:\Finance 27\lib\ui\widgets\jar_chart.dart"

with open(chart_path, 'r', encoding='utf-8') as f:
    c = f.read()

# 1. Update _Badge size to 55 in PieChartSectionData
c = c.replace("""                  badgeWidget: _Badge(
                    icon: _getIconForType(jar.type),
                    size: 30,""", """                  badgeWidget: _Badge(
                    icon: _getIconForType(jar.type),
                    size: 55,""")

# 2. Revert _Badge to use shape: BoxShape.circle and fixed width/height
old_badge_build = """  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      constraints: const BoxConstraints(maxWidth: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: size * 0.5,
            color: borderColor,
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (percentage.isNotEmpty) ...[
            Text(
              percentage,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
          ],
        ],
      ),
    );
  }"""

new_badge_build = """  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: size * 0.35,
            color: borderColor,
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (percentage.isNotEmpty) ...[
            Text(
              percentage,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
          ],
        ],
      ),
    );
  }"""

c = c.replace(old_badge_build, new_badge_build)

with open(chart_path, 'w', encoding='utf-8') as f:
    f.write(c)

print("Reverted to circular badge with size 55")
