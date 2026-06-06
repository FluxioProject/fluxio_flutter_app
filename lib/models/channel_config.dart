class ChannelConfig {
  String name;
  String unit;
  double min;
  double max;
  int decimals;
  bool visible;
  final bool analog;
  double mapMin; // valor físico correspondente a 4mA
  double mapMax; // valor físico correspondente a 20mA
  bool notifyMobile;
  bool notifyEmail;
  bool notifySms;

  ChannelConfig({
    required this.name,
    this.unit = '',
    this.min = 0,
    this.max = 100,
    this.decimals = 2,
    this.visible = true,
    this.analog = true,
    this.notifyMobile = false,
    this.notifyEmail = false,
    this.notifySms = false,
    this.mapMin = 0,
    this.mapMax = 100,
  });
}
