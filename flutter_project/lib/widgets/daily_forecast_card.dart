import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forecast_model.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_icons.dart';

class DailyForecastCard extends StatefulWidget {
  final DailyForecastModel day;
  final WeatherProvider provider;
  final bool initiallyExpanded;

  const DailyForecastCard({
    super.key,
    required this.day,
    required this.provider,
    this.initiallyExpanded = false,
  });

  @override
  State<DailyForecastCard> createState() => _DailyForecastCardState();
}

class _DailyForecastCardState extends State<DailyForecastCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = WeatherIconsHelper.getIconData(widget.day.condition, iconCode: widget.day.iconCode);
    final iconColor = WeatherIconsHelper.getConditionColor(widget.day.condition);
    final timeFormat = DateFormat('h:mm a');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded
              ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // Primary Summary Row
                Row(
                  children: [
                    // Day Name & Date
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.day.dayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d').format(widget.day.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Weather Icon & Condition
                    Icon(iconData, size: 26, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.day.condition,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.day.rainProbability > 0)
                            Row(
                              children: [
                                const Icon(Icons.water_drop, size: 10, color: Color(0xFF29B6F6)),
                                const SizedBox(width: 2),
                                Text(
                                  '${widget.day.rainProbability}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF29B6F6),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Min & Max Temperature
                    Row(
                      children: [
                        Text(
                          widget.provider.formatTemperature(widget.day.tempMin),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mini temp bar
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF64B5F6), Color(0xFFFFA726)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.provider.formatTemperature(widget.day.tempMax),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 6),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      size: 20,
                    ),
                  ],
                ),

                // Expanded Details Section
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  Divider(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniInfo(
                        context,
                        icon: Icons.air_rounded,
                        label: 'Wind',
                        value: widget.provider.formatWindSpeed(widget.day.windSpeed),
                      ),
                      _buildMiniInfo(
                        context,
                        icon: Icons.wb_sunny_outlined,
                        label: 'UV Index',
                        value: '${widget.day.uvIndex}',
                      ),
                      if (widget.day.sunrise != null)
                        _buildMiniInfo(
                          context,
                          icon: Icons.wb_twilight_rounded,
                          label: 'Sunrise',
                          value: timeFormat.format(widget.day.sunrise!),
                        ),
                      if (widget.day.sunset != null)
                        _buildMiniInfo(
                          context,
                          icon: Icons.nightlight_outlined,
                          label: 'Sunset',
                          value: timeFormat.format(widget.day.sunset!),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
