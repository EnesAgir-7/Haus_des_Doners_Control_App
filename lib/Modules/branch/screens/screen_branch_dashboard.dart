import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../models/branch_model.dart';
import '../../../models/user_model.dart';
import '../../../translations/locale_keys.g.dart';
import '../../inspector/providers/provider_auth.dart';

class ScreenBranchDashboard extends StatefulWidget {
  const ScreenBranchDashboard({super.key});

  @override
  State<ScreenBranchDashboard> createState() => _ScreenBranchDashboardState();
}

class _ScreenBranchDashboardState extends State<ScreenBranchDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ProviderAuth>(context, listen: false);
    final UserModel? user = auth.userModel;
    final String uid = user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(LocaleKeys.branch.tr()),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(Collections.branches)
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Branch profile not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final branch = BranchModel.fromFirestore(snapshot.data!);

          // Main content: tab views
          return Column(
            children: [
              // Basic header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.primaryDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      branch.address,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildOverview(branch),
                    _buildInspections(branch),
                    _buildNotifications(),
                    _buildDocuments(),
                    _buildTraining(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Inspections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Training',
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BranchModel branch) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Branch Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Name: ${branch.name}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Address: ${branch.address}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement request-to-change flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request change not implemented')),
              );
            },
            child: const Text('Request Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildInspections(BranchModel branch) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(Collections.inspections)
          .where(InspectionFields.branchId, isEqualTo: branch.id)
          .orderBy(InspectionFields.completedTime, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No inspections yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = data[InspectionFields.completedTime];
            final title = data[InspectionFields.branchName] ?? 'Inspection';
            return ListTile(
              title: Text(title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                date != null ? date.toString() : '',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {},
            );
          },
        );
      },
    );
  }

  Widget _buildNotifications() {
    return const Center(
      child: Text(
        'Notifications feed (branch)',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildDocuments() {
    return const Center(
      child: Text(
        'Documents list and download',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildTraining() {
    return const Center(
      child: Text(
        'Training videos and content',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
