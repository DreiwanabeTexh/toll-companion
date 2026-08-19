import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/toll_plaza.dart';
import '../models/toll_segment.dart';
import '../models/route_model.dart';
import '../models/emergency_contact.dart';
import '../models/guide_entry.dart';
import '../models/checklist_item.dart';
import '../models/route_briefing.dart';
import '../models/data_report.dart';

/// Central access point for Cloud Firestore collections.
///
/// Follows collection definitions in data-model.md:
/// - `tollPlazas` (Phase 4 exit graph)
/// - `tollSegments`
/// - `routes`
/// - `emergencyContacts`
/// - `guideEntries`
/// - `checklistItems` (Phase 2)
/// - `routeBriefings` (Phase 2)
/// - `dataReports` (Phase 3 write-only)
class FirestoreService {
  final FirebaseFirestore? _customFirestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<TollPlaza> get tollPlazasRef =>
      _firestore.collection('tollPlazas').withConverter<TollPlaza>(
            fromFirestore: (snapshot, _) => TollPlaza.fromFirestore(snapshot),
            toFirestore: (plaza, _) => plaza.toFirestore(),
          );

  CollectionReference<TollSegment> get tollSegmentsRef =>
      _firestore.collection('tollSegments').withConverter<TollSegment>(
            fromFirestore: (snapshot, _) => TollSegment.fromFirestore(snapshot),
            toFirestore: (segment, _) => segment.toFirestore(),
          );

  CollectionReference<RouteModel> get routesRef =>
      _firestore.collection('routes').withConverter<RouteModel>(
            fromFirestore: (snapshot, _) => RouteModel.fromFirestore(snapshot),
            toFirestore: (route, _) => route.toFirestore(),
          );

  CollectionReference<EmergencyContact> get emergencyContactsRef =>
      _firestore.collection('emergencyContacts').withConverter<EmergencyContact>(
            fromFirestore: (snapshot, _) =>
                EmergencyContact.fromFirestore(snapshot),
            toFirestore: (contact, _) => contact.toFirestore(),
          );

  CollectionReference<GuideEntry> get guideEntriesRef =>
      _firestore.collection('guideEntries').withConverter<GuideEntry>(
            fromFirestore: (snapshot, _) => GuideEntry.fromFirestore(snapshot),
            toFirestore: (entry, _) => entry.toFirestore(),
          );

  CollectionReference<ChecklistItem> get checklistItemsRef =>
      _firestore.collection('checklistItems').withConverter<ChecklistItem>(
            fromFirestore: (snapshot, _) =>
                ChecklistItem.fromFirestore(snapshot),
            toFirestore: (item, _) => item.toFirestore(),
          );

  CollectionReference<RouteBriefing> get routeBriefingsRef =>
      _firestore.collection('routeBriefings').withConverter<RouteBriefing>(
            fromFirestore: (snapshot, _) =>
                RouteBriefing.fromFirestore(snapshot),
            toFirestore: (briefing, _) => briefing.toFirestore(),
          );

  CollectionReference<DataReport> get dataReportsRef =>
      _firestore.collection('dataReports').withConverter<DataReport>(
            fromFirestore: (snapshot, _) => DataReport.fromFirestore(snapshot),
            toFirestore: (report, _) => report.toFirestore(),
          );
}
