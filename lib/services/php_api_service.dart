import 'package:dio/dio.dart';
import '../models/ebook.dart';

class PhpApiService {
  static final PhpApiService instance = PhpApiService._internal();
  factory PhpApiService() => instance;
  PhpApiService._internal();

  final Dio _dio = Dio();
  static const String _baseUrl = 'https://api-ebooks.loholearning.co.ke';

  Future<List<Ebook>> getCloudBooks() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/books',
      );
      if (response.statusCode == 200) {
        final List<dynamic> booksJson = response.data is List 
            ? response.data 
            : response.data['data'] ?? response.data['books'] ?? [];
        return booksJson.map((json) {
          return Ebook(
            id: json['id']?.toString() ?? '',
            title: json['title'] ?? '',
            author: json['author'] ?? json['publisher'] ?? '',
            serverUrl: json['pdf_url'] ?? json['pdfUrl'] ?? '',
            fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
            downloadedDate: json['created_at'] != null
                ? DateTime.tryParse(json['created_at'])
                : (json['addedDate'] != null 
                    ? DateTime.tryParse(json['addedDate'])
                    : DateTime.now()),
            grade: json['grade'] ?? '',
            category: json['category'] ?? 'Textbooks',
            coverImagePath: json['cover_url'] ?? json['coverUrl'],
            totalPages: 0,
            isDownloaded: false,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching cloud books: $e');
      return [];
    }
  }

  Future<List<Ebook>> getBooksByGrade(String grade) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/books',
        queryParameters: {'grade': grade},
      );
      if (response.statusCode == 200) {
        final List<dynamic> booksJson = response.data is List 
            ? response.data 
            : response.data['data'] ?? response.data['books'] ?? [];
        return booksJson.map((json) {
          return Ebook(
            id: json['id']?.toString() ?? '',
            title: json['title'] ?? '',
            author: json['author'] ?? json['publisher'] ?? '',
            serverUrl: json['pdf_url'] ?? json['pdfUrl'] ?? '',
            fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
            downloadedDate: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at'])
                : DateTime.now(),
            grade: json['grade'] ?? '',
            category: json['category'] ?? 'Textbooks',
            coverImagePath: json['cover_url'] ?? json['coverUrl'],
            totalPages: 0,
            isDownloaded: false,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching books by grade: $e');
      return [];
    }
  }

  Future<List<Ebook>> getBooksByCategory(String category) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/books',
        queryParameters: {'category': category},
      );

      if (response.statusCode == 200) {
        final List<dynamic> booksJson = response.data is List 
            ? response.data 
            : response.data['data'] ?? response.data['books'] ?? [];
        return booksJson.map((json) {
          return Ebook(
            id: json['id']?.toString() ?? '',
            title: json['title'] ?? '',
            author: json['author'] ?? json['publisher'] ?? '',
            serverUrl: json['pdf_url'] ?? json['pdfUrl'] ?? '',
            fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
            downloadedDate: json['created_at'] != null
                ? DateTime.tryParse(json['created_at'])
                : DateTime.now(),
            grade: json['grade'] ?? '',
            category: json['category'] ?? 'Textbooks',
            coverImagePath: json['cover_url'] ?? json['coverUrl'],
            totalPages: 0,
            isDownloaded: false,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching books by category: $e');
      return [];
    }
  }

  Future<List<Ebook>> searchBooks(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/books',
        queryParameters: {'search': query},
      );
      if (response.statusCode == 200) {
        final List<dynamic> booksJson = response.data is List 
            ? response.data 
            : response.data['data'] ?? response.data['books'] ?? [];
        return booksJson.map((json) {
          return Ebook(
            id: json['id']?.toString() ?? '',
            title: json['title'] ?? '',
            author: json['author'] ?? json['publisher'] ?? '',
            serverUrl: json['pdf_url'] ?? json['pdfUrl'] ?? '',
            fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
            downloadedDate: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at'])
                : DateTime.now(),
            grade: json['grade'] ?? '',
            category: json['category'] ?? 'Textbooks',
            coverImagePath: json['cover_url'] ?? json['coverUrl'],
            totalPages: 0,
            isDownloaded: false,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/books/$bookId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }
}