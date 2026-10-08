class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {}
  
  Future<void> scheduleTaskNotification(String taskId, String title, DateTime scheduledDate) async {}
  
  Future<void> cancelNotification(String taskId) async {}
}
