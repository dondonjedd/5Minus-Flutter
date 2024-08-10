import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtility {
  static String timeFormat(
    final DateTime? dateTime, {
    final String divider = ':',
  }) {
    if (dateTime is DateTime) {
      final time = TimeOfDay.fromDateTime(dateTime);
      return '${time.hourOfPeriod}$divider${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'am' : 'pm'}';
    } else {
      return '-';
    }
  }

  static String dateFormat(
    final DateTime? dateTime, {
    final bool isShortForm = false,
  }) {
    if (dateTime is DateTime) {
      if (isShortForm) {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      } else {
        return '${dateTime.day} ${monthName(dateTime.month)} ${dateTime.year}';
      }
    } else {
      return '';
    }
  }

  static String? dateTimeFormat(final DateTime? dateTime) {
    if (dateTime is DateTime) {
      return '${dateFormat(dateTime, isShortForm: true)} ${timeFormat(dateTime)}';
    } else {
      return null;
    }
  }

  static DateTime? parseDateTimeNetwork(final String? dateTimeString) {
    if (dateTimeString?.isEmpty ?? true) return null;

    if (dateTimeString?.isNotEmpty ?? false) {
      final dateTimeSplitList = dateTimeString?.split(' ') ?? [];

      final currentDateTime = DateTime.now();
      final dateList = dateTimeSplitList[0].split('-');

      final year = int.tryParse(dateList[0]) ?? currentDateTime.year;
      final month = int.tryParse(dateList[1]) ?? currentDateTime.month;
      final day = int.tryParse(dateList[2]) ?? currentDateTime.day;

      int hour = 0;
      int minute = 0;
      int second = 0;

      if (dateTimeSplitList.length > 1) {
        final timeList = dateTimeSplitList[1].split(':');
        if (timeList.isNotEmpty) {
          hour = int.tryParse(timeList[0]) ?? currentDateTime.hour;
          if (timeList.length > 1) {
            minute = int.tryParse(timeList[1]) ?? currentDateTime.minute;
            if (timeList.length > 2) {
              second = int.tryParse(timeList[2]) ?? currentDateTime.second;
            }
          }
        }
      }

      return DateTime(year, month, day, hour, minute, second);
    }
    return null;
  }

  static String monthName(final int month) {
    switch (month) {
      case DateTime.january:
        return 'January';
      case DateTime.february:
        return 'February';
      case DateTime.march:
        return 'March';
      case DateTime.april:
        return 'April';
      case DateTime.may:
        return 'May';
      case DateTime.june:
        return 'June';
      case DateTime.july:
        return 'July';
      case DateTime.august:
        return 'August';
      case DateTime.september:
        return 'September';
      case DateTime.october:
        return 'October';
      case DateTime.november:
        return 'November';
      case DateTime.december:
        return 'December';
      default:
        return 'Unknown';
    }
  }

  static String weekName(final DateTime? dateTime) {
    switch (dateTime?.weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thur';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '-';
    }
  }

  DateTimeUtility._();

  static DateTime? parseDateDashddMMyyyy(String dateString) {
    if (dateString.isEmpty) return null;

    // Split the date string by "-"
    List<String> parts = dateString.split('-');

    // Extract day, month, and year from the split parts
    int? day = int.tryParse(parts[0]);
    int? month = int.tryParse(parts[1]);
    int? year = int.tryParse(parts[2]);

    // Create a DateTime object
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }

    return null;
  }

  static DateTime? parseDateSlashddMMyyyy(String dateString) {
    if (dateString.isEmpty) return null;
    // Split the date string by "-"
    List<String> parts = dateString.split('/');

    // Extract day, month, and year from the split parts
    int? day = int.tryParse(parts[0]);
    int? month = int.tryParse(parts[1]);
    int? year = int.tryParse(parts[2]);

    // Create a DateTime object
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }

    return null;
  }

  // Custom function to parse the date string
  static DateTime? parseDateDashddMMMyyyy(String dateString) {
    if (dateString.isEmpty) return null;

    final List<String> monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    List<String> dateParts = dateString.split('-');
    int? day = int.tryParse(dateParts[0]); // Default to 1 if invalid day
    int? monthIndex = monthNames.indexOf(dateParts[1].toUpperCase());
    int? year = int.tryParse(dateParts[2]); // Default to 2000 if invalid year

    if (monthIndex < 0) {
      monthIndex = 0; // Default to January if invalid month
    }
    if (year != null && day != null) {
      return DateTime(year, monthIndex + 1, day);
    }
    return null;
  }

  // Custom function to format the date into "dd/MM/yyyy" format
  static String formatDateSlashddMMyyyy(DateTime? date) {
    if (date == null) return '';
    String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    return formattedDate;
  }

  // Custom function to format the date into "yyyy-MM-dd" format
  static String formatDateDashyyyyMMdd(DateTime date) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return formattedDate;
  }

  // Custom function to format the date into "yyyy-MM-dd" format
  static String converStringddMMyyyyFROMyyyyMMdd(String date) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(date));
    return formattedDate;
  }

  // Custom function to format the date into "yyyy-MM-dd" format
  static String converStringddMMyyyyFROMddMMyyyy(String date) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateFormat('dd-MM-yyyy').parse(date));
    return formattedDate;
  }

  static String converStringyyyyMMDDFROMddMMyyyy(String date) {
    if (date.isEmpty) return '';
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(date));
      return formattedDate;
    } catch (e) {
      return '';
    }
  }

  static String formatDateUtcStringToLocaldMMM(String utcString) {
    try {
      if (utcString.isEmpty) {
        return '-';
      }
      // Parse the date string
      DateTime dateTime = DateTime.parse(utcString);

      // Format the date to the desired format
      DateFormat formatter = DateFormat('d MMM');
      String formattedDate = formatter.format(dateTime);

      return formattedDate;
    } catch (e) {
      return '-';
    }
  }

  static String formatDateUtcStringToLocalddMMYY(String utcString) {
    try {
      if (utcString.isEmpty) {
        return '-';
      }
      // Parse the date string
      DateTime dateTime = DateTime.parse(utcString);

      // Format the date to the desired format
      DateFormat formatter = DateFormat('dd MMMM yyyy');
      String formattedDate = formatter.format(dateTime);

      return formattedDate;
    } catch (e) {
      return '-';
    }
  }
}
