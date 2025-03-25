extension ImagePath on String {
  String get png => "assets/images/$this.png";
  String get jpg => "assets/images/$this.jpg";
  String get jpeg => "assets/images/$this.jpeg";
  String get gif => "assets/gif/$this.gif";
  String get svg => "assets/icons/$this.svg";
}
