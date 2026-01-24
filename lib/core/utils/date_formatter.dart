import 'package:intl/intl.dart';

class DateFormatter {
  // Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Format time as HH:MM:SS
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }
  
  // Format date and time as DD/MM/YYYY HH:MM:SS
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }
  
  // Format timestamp from Firestore
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return formatDateTime(date);
  }
}
