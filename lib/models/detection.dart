 class Detection {
    final String label;
    final double confidence;
    final double xmin;
    final double ymin;
    final double xmax;
    final double ymax;

    const Detection({
      required this.label,
      required this.confidence,
      required this.xmin,
      required this.ymin,
      required this.xmax,
      required this.ymax,
    });
  }