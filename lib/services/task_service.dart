import 'package:dio/dio.dart';
import 'api_client.dart';
import 'local_storage.dart';

class TaskService {
  final _api = ApiClient();

  Future<List<dynamic>> getTasks({
    String? status,
    String? priority,
    String? category,
    String? from,
    String? to,
    String? search,
  }) async {
    try {
      final res = await _api.get('/tasks', params: {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (search != null) 'search': search,
      });
      final tasks = res.data['tasks'] as List;
      await LocalStorage.saveAllTasks(tasks);
      return tasks;
    } on DioException {
      return LocalStorage.getAllTasks();
    }
  }

  Future<List<dynamic>> getTodayTasks() async {
    try {
      final res = await _api.get('/tasks/today');
      final tasks = res.data['tasks'] as List;
      await LocalStorage.saveTodayTasks(tasks);
      // Upsert today's tasks into all_tasks so overdue detection and
      // deadline predictions always have current data.
      await _mergeIntoAllTasks(tasks);
      return tasks;
    } on DioException {
      return LocalStorage.getTodayTasks();
    }
  }

  /// Upserts [tasks] into the all_tasks cache without discarding existing
  /// tasks from other days.
  Future<void> _mergeIntoAllTasks(List<dynamic> tasks) async {
    final all = LocalStorage.getAllTasks();
    for (final raw in tasks) {
      final task = raw as Map<String, dynamic>;
      final id = task['id'];
      final idx = all.indexWhere((t) => t['id'] == id);
      if (idx >= 0) {
        all[idx] = task;
      } else {
        all.add(task);
      }
    }
    await LocalStorage.saveAllTasks(all);
  }

  Future<List<dynamic>> getOverdueTasks() async {
    try {
      final res = await _api.get('/tasks/overdue');
      return res.data['tasks'] as List;
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    final res = await _api.get('/tasks/$id');
    return res.data['task'] as Map<String, dynamic>;
  }

  /// Returns instantly with a locally-cached task — never waits on the
  /// network (which can take a long time if the backend is cold-starting).
  /// The real create request fires in the background and swaps the task's
  /// temporary ID for the server one once it lands, or queues it as a
  /// pending op if it fails.
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    String? dueDate,
    String? startTime,
    int? estimatedDuration,
    String? category,
    String? priority,
    String? recurrenceType,
    List<String>? subtasks,
    String? remindAt,
  }) async {
    final data = {
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'dueDate': dueDate,
      if (startTime != null) 'startTime': startTime,
      if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (recurrenceType != null) 'recurrenceType': recurrenceType,
      if (subtasks != null) 'subtasks': subtasks,
      if (remindAt != null) 'remindAt': remindAt,
    };

    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = {
      'id': tempId,
      'title': title,
      'priority': priority ?? 'MEDIUM',
      'isCompleted': false,
      ...data,
    };
    final cached = LocalStorage.getTodayTasks();
    cached.add(optimistic);
    await LocalStorage.saveTodayTasks(cached);

    _createTaskInBackground(tempId, data);
    return optimistic;
  }

  Future<void> _createTaskInBackground(
      String tempId, Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/tasks', data: data);
      final task = res.data['task'] as Map<String, dynamic>;
      final today = LocalStorage.getTodayTasks();
      final idx = today.indexWhere((t) => t['id'] == tempId);
      if (idx != -1) {
        // Keep the old tempId so cancelAllReminders can cancel notification
        // slots that were originally scheduled under the optimistic ID.
        today[idx] = {...task, '_tempId': tempId};
        await LocalStorage.saveTodayTasks(today);
      }
    } catch (_) {
      // Backend unreachable — keep the optimistic copy and sync it later.
      await LocalStorage.addPendingOp({'type': 'createTask', 'data': data, 'tempId': tempId});
    }
  }

  Future<Map<String, dynamic>> createFromNLP(String text) async {
    final res = await _api.post('/tasks/nlp', data: {'text': text});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final res = await _api.put('/tasks/$id', data: updates);
    return res.data['task'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeTask(String id) async {
    // If the task was created optimistically and the server hasn't confirmed
    // it yet, the real ID doesn't exist on the server — skip the network call
    // and queue it; syncPendingOps will retry after the task is created.
    if (id.startsWith('pending_')) {
      await _markCompletedInCache(id);
      await LocalStorage.addPendingOp({'type': 'completeTask', 'id': id});
      return {'id': id, 'isCompleted': true};
    }
    try {
      final res = await _api.patch('/tasks/$id/complete');
      final task = res.data['task'] as Map<String, dynamic>;
      await _markCompletedInCache(id);
      return task;
    } on DioException {
      await LocalStorage.addPendingOp({'type': 'completeTask', 'id': id});
      await _markCompletedInCache(id);
      final cached = LocalStorage.getTodayTasks();
      final idx = cached.indexWhere((t) => t['id'] == id);
      if (idx != -1) return cached[idx];
      return {'id': id, 'isCompleted': true};
    }
  }

  Future<void> _markCompletedInCache(String id) async {
    // today_tasks
    final today = LocalStorage.getTodayTasks();
    final ti = today.indexWhere((t) => t['id'] == id);
    if (ti != -1) {
      today[ti] = {...today[ti], 'isCompleted': true};
      await LocalStorage.saveTodayTasks(today);
    }
    // all_tasks — keeps deadline predictor and overdue count in sync
    final all = LocalStorage.getAllTasks();
    final ai = all.indexWhere((t) => t['id'] == id);
    if (ai != -1) {
      all[ai] = {...all[ai], 'isCompleted': true};
      await LocalStorage.saveAllTasks(all);
    }
  }

  Future<void> deleteTask(String id) async {
    await _api.delete('/tasks/$id');
    // Remove from both caches so predictions don't include deleted tasks.
    final today = LocalStorage.getTodayTasks();
    today.removeWhere((t) => t['id'] == id);
    await LocalStorage.saveTodayTasks(today);

    final all = LocalStorage.getAllTasks();
    all.removeWhere((t) => t['id'] == id);
    await LocalStorage.saveAllTasks(all);
  }

  Future<Map<String, dynamic>> addSubtask(String taskId, String title) async {
    final res =
        await _api.post('/tasks/$taskId/subtasks', data: {'title': title});
    return res.data['subtask'] as Map<String, dynamic>;
  }

  Future<void> completeSubtask(String subtaskId,
      {bool completed = true}) async {
    await _api.patch('/tasks/subtasks/$subtaskId/complete',
        data: {'isCompleted': completed});
  }

  /// Call on app launch when back online — push pending ops to server
  Future<void> syncPendingOps() async {
    final ops = LocalStorage.getPendingOps();
    if (ops.isEmpty) return;
    final synced = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        if (op['type'] == 'createTask') {
          await _api.post('/tasks', data: op['data']);
          synced.add(op);
        } else if (op['type'] == 'completeTask') {
          await _api.patch('/tasks/${op['id']}/complete');
          synced.add(op);
        }
      } catch (_) {
        break; // still offline — stop and retry later
      }
    }
    if (synced.isNotEmpty) {
      final remaining =
          ops.where((o) => !synced.contains(o)).toList();
      await LocalStorage.clearPendingOps();
      for (final op in remaining) {
        await LocalStorage.addPendingOp(op);
      }
      // Refresh cache after sync
      await getTodayTasks();
    }
  }
}
