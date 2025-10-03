class DymmyBranch {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double? averageScore;
  final int totalInspections;

  DymmyBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.averageScore,
    this.totalInspections = 0,
  });
}

  final List<DymmyBranch> dummyBranches = [
    DymmyBranch(
      id: 'b1',
      name: 'Central Branch',
      address: '123 Main Street, City A',
      latitude: 40.7128,
      longitude: -74.0060,
      imageUrl:
          'https://images.unsplash.com/photo-1560184897-5b6a3f12d97b?fit=crop&w=400&q=80',
      averageScore: 8.5,
      totalInspections: 25,
    ),
    DymmyBranch(
      id: 'b2',
      name: 'North Branch',
      address: '456 North Avenue, City B',
      latitude: 40.7306,
      longitude: -73.9352,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154340-be6161e7b6fc?fit=crop&w=400&q=80',
      averageScore: 9.2,
      totalInspections: 30,
    ),
    DymmyBranch(
      id: 'b3',
      name: 'East Branch',
      address: '789 East Blvd, City C',
      latitude: 40.7411,
      longitude: -73.9897,
      imageUrl:
          'https://images.unsplash.com/photo-1581091012184-1e0b1c9f02d0?fit=crop&w=400&q=80',
      averageScore: 7.8,
      totalInspections: 20,
    ),
    DymmyBranch(
      id: 'b4',
      name: 'West Branch',
      address: '321 West Road, City D',
      latitude: 40.7510,
      longitude: -73.9690,
      imageUrl:
          'https://images.unsplash.com/photo-1573497160914-d3f2f9c1c0d2?fit=crop&w=400&q=80',
      averageScore: 8.0,
      totalInspections: 18,
    ),
    DymmyBranch(
      id: 'b5',
      name: 'South Branch',
      address: '654 South Lane, City E',
      latitude: 40.7580,
      longitude: -73.9855,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154051-0f0dbe33807f?fit=crop&w=400&q=80',
      averageScore: 7.5,
      totalInspections: 22,
    ),
    DymmyBranch(
      id: 'b6',
      name: 'Green Park Branch',
      address: '12 Green Park, City F',
      latitude: 40.7625,
      longitude: -73.9730,
      imageUrl:
          'https://images.unsplash.com/photo-1598300057565-7d1b7e4e646b?fit=crop&w=400&q=80',
      averageScore: 9.0,
      totalInspections: 27,
    ),
    DymmyBranch(
      id: 'b7',
      name: 'Lakeview Branch',
      address: '34 Lakeview Ave, City G',
      latitude: 40.7700,
      longitude: -73.9810,
      imageUrl:
          'https://images.unsplash.com/photo-1598928506315-3f02db0315be?fit=crop&w=400&q=80',
      averageScore: 8.3,
      totalInspections: 19,
    ),
    DymmyBranch(
      id: 'b8',
      name: 'Hilltop Branch',
      address: '78 Hilltop Rd, City H',
      latitude: 40.7750,
      longitude: -73.9695,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154197-c8cfb2c83a30?fit=crop&w=400&q=80',
      averageScore: 8.7,
      totalInspections: 23,
    ),
    DymmyBranch(
      id: 'b9',
      name: 'Riverside Branch',
      address: '90 Riverside St, City I',
      latitude: 40.7800,
      longitude: -73.9580,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154317-9f9b2c9f8d30?fit=crop&w=400&q=80',
      averageScore: 7.9,
      totalInspections: 21,
    ),
    DymmyBranch(
      id: 'b10',
      name: 'Downtown Branch',
      address: '100 Downtown Blvd, City J',
      latitude: 40.7850,
      longitude: -73.9450,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154417-8f8a2b8f6e20?fit=crop&w=400&q=80',
      averageScore: 8.9,
      totalInspections: 26,
    ),
    // Add remaining 10
    DymmyBranch(
      id: 'b11',
      name: 'Sunset Branch',
      address: '23 Sunset Ave, City K',
      latitude: 40.7900,
      longitude: -73.9400,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154517-7f7b2b7f7d30?fit=crop&w=400&q=80',
      averageScore: 8.1,
      totalInspections: 20,
    ),
    DymmyBranch(
      id: 'b12',
      name: 'Bayview Branch',
      address: '45 Bayview Rd, City L',
      latitude: 40.7950,
      longitude: -73.9350,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154617-6f6a2a6f6b30?fit=crop&w=400&q=80',
      averageScore: 9.3,
      totalInspections: 28,
    ),
    DymmyBranch(
      id: 'b13',
      name: 'Mountain Branch',
      address: '67 Mountain St, City M',
      latitude: 40.8000,
      longitude: -73.9300,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154717-5f5a2a5f5a30?fit=crop&w=400&q=80',
      averageScore: 8.2,
      totalInspections: 19,
    ),
    DymmyBranch(
      id: 'b14',
      name: 'Harbor Branch',
      address: '89 Harbor Blvd, City N',
      latitude: 40.8050,
      longitude: -73.9250,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154817-4f4a2a4f4a30?fit=crop&w=400&q=80',
      averageScore: 7.7,
      totalInspections: 18,
    ),
    DymmyBranch(
      id: 'b15',
      name: 'Garden Branch',
      address: '12 Garden Rd, City O',
      latitude: 40.8100,
      longitude: -73.9200,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154917-3f3a2a3f3a30?fit=crop&w=400&q=80',
      averageScore: 8.6,
      totalInspections: 22,
    ),
    DymmyBranch(
      id: 'b16',
      name: 'Ridge Branch',
      address: '34 Ridge St, City P',
      latitude: 40.8150,
      longitude: -73.9150,
      imageUrl:
          'https://images.unsplash.com/photo-1600585155017-2f2a2a2f2a30?fit=crop&w=400&q=80',
      averageScore: 8.4,
      totalInspections: 21,
    ),
    DymmyBranch(
      id: 'b17',
      name: 'Canyon Branch',
      address: '56 Canyon Rd, City Q',
      latitude: 40.8200,
      longitude: -73.9100,
      imageUrl:
          'https://images.unsplash.com/photo-1600585155117-1f1a1a1f1a30?fit=crop&w=400&q=80',
      averageScore: 7.8,
      totalInspections: 19,
    ),
    DymmyBranch(
      id: 'b18',
      name: 'Meadow Branch',
      address: '78 Meadow St, City R',
      latitude: 40.8250,
      longitude: -73.9050,
      imageUrl:
          'https://images.unsplash.com/photo-1600585155217-0f0a0a0f0a30?fit=crop&w=400&q=80',
      averageScore: 8.9,
      totalInspections: 25,
    ),
    DymmyBranch(
      id: 'b19',
      name: 'Forest Branch',
      address: '90 Forest Rd, City S',
      latitude: 40.8300,
      longitude: -73.9000,
      imageUrl:
          'https://images.unsplash.com/photo-1600585155317-ff0f0f0f0f30?fit=crop&w=400&q=80',
      averageScore: 8.0,
      totalInspections: 20,
    ),
    DymmyBranch(
      id: 'b20',
      name: 'Valley Branch',
      address: '12 Valley Blvd, City T',
      latitude: 40.8350,
      longitude: -73.8950,
      imageUrl:
          'https://images.unsplash.com/photo-1600585155417-ee0e0e0e0e30?fit=crop&w=400&q=80',
      averageScore: 8.7,
      totalInspections: 23,
    ),
  ];
