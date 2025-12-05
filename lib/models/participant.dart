import 'package:flutter/material.dart';

class Participant {
  final String pid;
  final String study;
  final DateTime enrollmentDate;

  Participant({
    required this.pid,
    required this.study,
    required this.enrollmentDate,
  });
}
