import 'dart:async';

import 'package:flutter/material.dart';

import 'package:todo_app/services/notification_service.dart';

class DebugPermissionsScreen extends StatefulWidget {
  const DebugPermissionsScreen({super.key});

  @override
  State<DebugPermissionsScreen> createState() => _DebugPermissionsScreenState();
}

class _DebugPermissionsScreenState extends State<DebugPermissionsScreen> {
  Map<String, dynamic> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    final status = await NotificationService.getPermissionStatus();
    setState(() {
      _permissionStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Debug'),
        actions: [
          IconButton(
            onPressed: _loadPermissionStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permission Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._permissionStatus.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text(entry.value.toString()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.resetPermissions();
              _loadPermissionStatus();
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Permissions reset')),
                );
              }
            },
            child: const Text('Reset Permissions (Testing Only)'),
          ),
        ],
      ),
    );
  }
}
