import os

chart_path = r"C:\Finance 27\lib\ui\widgets\jar_chart.dart"

with open(chart_path, 'r', encoding='utf-8') as f:
    c = f.read()

# Replace _Badge instantiation
import re

old_section = """              sections: jars.map((jar) {
                final amount = monthlyStats.jarBalances[jar.type]?[currentCurrency] ?? 0.0;
                return PieChartSectionData(
                  color: _getColorForType(jar.type, theme),
                  value: amount > 0 ? amount : 1,
                  title: '',
                  radius: 35,
                  badgeWidget: _Badge(
                    icon: _getIconForType(jar.type),
                    size: 26,
                    borderColor: _getColorForType(jar.type, theme),
                  ),
                  badgePositionPercentageOffset: 1.25,
                );"""

new_section = """              sections: jars.map((jar) {
                final amount = monthlyStats.jarBalances[jar.type]?[currentCurrency] ?? 0.0;
                final double percent = totalBalance > 0 ? (amount / totalBalance * 100) : 0.0;
                final String percentStr = percent > 0 ? '${percent.toStringAsFixed(1)}%' : '';
                final String displayName = jar.customName ?? AppStrings.get(ref, jar.type.displayName);
                
                return PieChartSectionData(
                  color: _getColorForType(jar.type, theme),
                  value: amount > 0 ? amount : 1,
                  title: '',
                  radius: 35,
                  badgeWidget: _Badge(
                    icon: _getIconForType(jar.type),
                    size: 30,
                    borderColor: _getColorForType(jar.type, theme),
                    name: displayName,
                    percentage: percentStr,
                  ),
                  badgePositionPercentageOffset: 1.25,
                );"""

c = c.replace(old_section, new_section)

old_badge = """class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;

  const _Badge({
    Key? key,
    required this.icon,
    required this.size,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(
          icon,
          size: size * .6,
          color: borderColor,
        ),
      ),
    );
  }
}"""

new_badge = """class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;
  final String name;
  final String percentage;

  const _Badge({
    Key? key,
    required this.icon,
    required this.size,
    required this.borderColor,
    this.name = '',
    this.percentage = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
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
  }
}"""

c = c.replace(old_badge, new_badge)

with open(chart_path, 'w', encoding='utf-8') as f:
    f.write(c)

print("Updated badges in jar chart")
