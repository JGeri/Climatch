class IconMapper {
  static String fromCondition(String condition) {
    switch (condition) {
      case 'cloudy-with-sun':
        return 'assets/images/icons/cloudy-with-sun.png';
      case 'cloudy':
        return 'assets/images/icons/cloudy.png';
      case 'moon':
        return 'assets/images/icons/moon.png';
      case 'rain-showers-with-sun':
        return 'assets/images/icons/rain-showers-with-sun.png';
      case 'rain':
        return 'assets/images/icons/rain.png';
      case 'snow':
        return 'assets/images/icons/snow.png';
      case 'storm':
        return 'assets/images/icons/storm.png';
      case 'sunny':
      default:
        return 'assets/images/icons/sunny.png';
    }
  }

  static String fromOwmIcon(String? code) {
    switch (code) {
      case '01d':
        return 'assets/images/icons/sunny.png';
      case '01n':
        return 'assets/images/icons/moon.png';
      case '02d':
        return 'assets/images/icons/cloudy-with-sun.png';
      case '02n':
        return 'assets/images/icons/cloudy.png';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return 'assets/images/icons/cloudy.png';
      case '09d':
      case '09n':
        return 'assets/images/icons/rain.png';
      case '10d':
        return 'assets/images/icons/rain-showers-with-sun.png';
      case '10n':
        return 'assets/images/icons/rain.png';
      case '11d':
      case '11n':
        return 'assets/images/icons/storm.png';
      case '13d':
      case '13n':
        return 'assets/images/icons/snow.png';
      case '50d':
      case '50n':
        return 'assets/images/icons/cloudy.png';
      default:
        return 'assets/images/icons/sunny.png';
    }
  }
}
