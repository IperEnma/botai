import 'package:flutter/material.dart';

enum BranchStatus { activa, pausada }

class Branch {
  final String id;
  final String name;
  final String initials;
  final String address;
  final Color color;
  final BranchStatus status;
  final DateTime createdAt;

  const Branch({
    required this.id,
    required this.name,
    required this.initials,
    required this.address,
    required this.color,
    required this.status,
    required this.createdAt,
  });
}
