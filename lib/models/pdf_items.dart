import 'package:equatable/equatable.dart';

class PdfItem extends Equatable {
  final String name;
  final String downloadUrl;
  final String htmlUrl;

  const PdfItem({
    required this.name,
    required this.downloadUrl,
    required this.htmlUrl,
  });

  factory PdfItem.fromJson(Map<String, dynamic> json) {
    return PdfItem(
      name: json['name'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      htmlUrl: json['html_url'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, downloadUrl, htmlUrl];
}
