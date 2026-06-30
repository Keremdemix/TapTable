class LayoutConstants {
  static const double chairSize = 14;

  /// Kat planının "sanal" çizim alanı — ekran boyutundan bağımsız, sabit.
  /// InteractiveViewer (constrained: false) bu alanı zoom/pan ile gösterir.
  /// Sağdaki panel zaten Row içinde sabit genişlikte olduğundan, canvas'ın
  /// görünür kısmı otomatik olarak "kalan alan" kadar olur — ayrıca yüzde
  /// hesabına gerek yok.
  static const double canvasWidth = 1200;
  static const double canvasHeight = 900;
}