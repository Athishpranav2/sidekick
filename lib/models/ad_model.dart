import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? sponsorName;
  final String? sponsorLogoUrl;
  final String? callToAction;
  final String? targetUrl;
  final DateTime createdAt;
  final bool isActive;
  final String? category;
  final Map<String, dynamic>? metadata;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.callToAction,
    this.targetUrl,
    required this.createdAt,
    this.isActive = true,
    this.category,
    this.metadata,
  });

  factory AdModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AdModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      sponsorName: data['sponsorName'],
      sponsorLogoUrl: data['sponsorLogoUrl'],
      callToAction: data['callToAction'],
      targetUrl: data['targetUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      category: data['category'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'sponsorName': sponsorName,
      'sponsorLogoUrl': sponsorLogoUrl,
      'callToAction': callToAction,
      'targetUrl': targetUrl,
      'createdAt': createdAt,
      'isActive': isActive,
      'category': category,
      'metadata': metadata,
    };
  }
}
