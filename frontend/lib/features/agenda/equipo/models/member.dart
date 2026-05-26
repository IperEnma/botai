import 'package:flutter/material.dart';

enum MemberType { profesionalConCuenta, profesionalSoloPerfil, recepcion }

enum MemberStatus { activo, pausado }

enum MemberRole { duenio, profesional, recepcion }

class DaySchedule {
  final bool open;
  final String? from;
  final String? to;

  const DaySchedule({required this.open, this.from, this.to});

  Map<String, dynamic> toJson() => {
        'open': open,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        open: json['open'] as bool? ?? false,
        from: json['from'] as String?,
        to: json['to'] as String?,
      );
}

class WeekSchedule {
  final DaySchedule lunes;
  final DaySchedule martes;
  final DaySchedule miercoles;
  final DaySchedule jueves;
  final DaySchedule viernes;
  final DaySchedule sabado;
  final DaySchedule domingo;

  const WeekSchedule({
    required this.lunes,
    required this.martes,
    required this.miercoles,
    required this.jueves,
    required this.viernes,
    required this.sabado,
    required this.domingo,
  });

  Map<String, dynamic> toJson() => {
        'lunes': lunes.toJson(),
        'martes': martes.toJson(),
        'miercoles': miercoles.toJson(),
        'jueves': jueves.toJson(),
        'viernes': viernes.toJson(),
        'sabado': sabado.toJson(),
        'domingo': domingo.toJson(),
      };

  factory WeekSchedule.fromJson(Map<String, dynamic> json) => WeekSchedule(
        lunes: DaySchedule.fromJson(
            (json['lunes'] as Map<String, dynamic>?) ?? {}),
        martes: DaySchedule.fromJson(
            (json['martes'] as Map<String, dynamic>?) ?? {}),
        miercoles: DaySchedule.fromJson(
            (json['miercoles'] as Map<String, dynamic>?) ?? {}),
        jueves: DaySchedule.fromJson(
            (json['jueves'] as Map<String, dynamic>?) ?? {}),
        viernes: DaySchedule.fromJson(
            (json['viernes'] as Map<String, dynamic>?) ?? {}),
        sabado: DaySchedule.fromJson(
            (json['sabado'] as Map<String, dynamic>?) ?? {}),
        domingo: DaySchedule.fromJson(
            (json['domingo'] as Map<String, dynamic>?) ?? {}),
      );
}

class Member {
  final String id;
  final String name;
  final MemberType type;
  final MemberStatus status;
  final MemberRole role;
  final Color color;
  final String? phone;
  final String? email;
  final String? title;
  final String? bio;
  final String? avatarUrl;
  final List<String> serviceIds;
  final WeekSchedule? customSchedule;
  final DateTime joinedAt;
  final int turnosCompletados;
  final double avgRating;
  final int turnosHoy;
  final bool inviteAccepted;
  final DateTime? inviteAcceptedAt;
  final DateTime? lastSeen;

  const Member({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.role,
    required this.color,
    this.phone,
    this.email,
    this.title,
    this.bio,
    this.avatarUrl,
    required this.serviceIds,
    this.customSchedule,
    required this.joinedAt,
    required this.turnosCompletados,
    required this.avgRating,
    required this.turnosHoy,
    required this.inviteAccepted,
    this.inviteAcceptedAt,
    this.lastSeen,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String get typeLabel => switch (type) {
        MemberType.profesionalConCuenta => 'PROFESIONAL · CON CUENTA',
        MemberType.profesionalSoloPerfil => 'PROFESIONAL · SOLO PERFIL',
        MemberType.recepcion => 'RECEPCIÓN · CON CUENTA',
      };

  bool get hasAccount => type != MemberType.profesionalSoloPerfil;

  bool get isCustomSchedule => customSchedule != null;

  Member copyWith({
    String? id,
    String? name,
    MemberType? type,
    MemberStatus? status,
    MemberRole? role,
    Color? color,
    String? phone,
    String? email,
    String? title,
    String? bio,
    String? avatarUrl,
    List<String>? serviceIds,
    WeekSchedule? customSchedule,
    bool clearCustomSchedule = false,
    DateTime? joinedAt,
    int? turnosCompletados,
    double? avgRating,
    int? turnosHoy,
    bool? inviteAccepted,
    DateTime? inviteAcceptedAt,
    DateTime? lastSeen,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      role: role ?? this.role,
      color: color ?? this.color,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      serviceIds: serviceIds ?? this.serviceIds,
      customSchedule:
          clearCustomSchedule ? null : (customSchedule ?? this.customSchedule),
      joinedAt: joinedAt ?? this.joinedAt,
      turnosCompletados: turnosCompletados ?? this.turnosCompletados,
      avgRating: avgRating ?? this.avgRating,
      turnosHoy: turnosHoy ?? this.turnosHoy,
      inviteAccepted: inviteAccepted ?? this.inviteAccepted,
      inviteAcceptedAt: inviteAcceptedAt ?? this.inviteAcceptedAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
