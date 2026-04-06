import 'dart:io';

class AdConfig {
  const AdConfig._();

  static String get homeBanner1 {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/7988227382';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/8865877557';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get homeBanner2 {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/5263156340';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/1323911334';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get devedoresBanner {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/2185608422';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/9922591661';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }

  static String get appOpen {
    if (Platform.isAndroid) return 'ca-app-pub-3652623512305285/5018170803';
    if (Platform.isIOS) return 'ca-app-pub-3652623512305285/1467067906';
    throw UnsupportedError('Plataforma não suportada para anúncios');
  }
}
