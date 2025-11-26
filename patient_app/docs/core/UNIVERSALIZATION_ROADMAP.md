Status: ACTIVE

# Universalization Roadmap: From Health App to Personal Information System

## Current State Analysis

### What We Have (Strong Foundations)

**1. Core Infrastructure** ✅
- Local-first storage with Isar (flexible NoSQL database)
- Attachment system for files (photos, PDFs, audio, documents)
- Encrypted backup/restore to Google Drive
- Auto-sync with Wi-Fi gating and cadence presets
- Multi-modal capture (photo, scan, voice, file, email)
- Modern design system with gradient UI
- Authentication module (in progress)

**2. Data Model** (Health-Focused)
```dart
RecordEntity {
  id, type, date, title, text, tags[],
  createdAt, updatedAt, deletedAt
}

Attachment {
  recordId, path, kind, mimeType, sizeBytes,
  ocrText, capturedAt, source, metadataJson
}
```

**Current Types**: `visit`, `lab`, `medication`, `note`

**3. Features**
- CRUD operations for health records
- Search and pagination
- Multi-modal capture with review flow
- Sync and backup
- Settings and profile hub

### What Needs to Change

**1. Domain-Specific Limitations**
- Hard-coded health record types (`visit`, `lab`, `medication`, `note`)
- Health-centric terminology throughout codebase
- UI assumes medical context (icons, labels, workflows)
- No concept of "life areas" or "domains"

**2. Rigid Structure**
- Fixed schema for all records
- No custom fields per domain
- Categories are predefined, not user-defined
- No domain-specific templates or workflows

**3. Single-Purpose UI**
- Navigation assumes health records only
- No way to switch between different life areas
- Icons and colors are health-themed
- No personalization for different use cases

## Universalization Strategy

### Phase 1: Foundation - Domain-Agnostic Core (Months 1-2)

**Goal**: Generalize the data model and core systems without breaking existing functionality.

#### 1.1 Introduce "Information Item" Concept

**Create Universal Item Entity**:
```dart
// lib/core/domain/entities/information_item.dart
class InformationItem {
  final int? id;
  final String domain;        // 'health', 'notes', 'projects', etc.
  final String category;      // flexible, domain-specific
  final DateTime date;
  final String title;
  final String? content;
  final List<String> tags;
  final Map<String, dynamic>? customFields;  // domain-specific data
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}
```

**Migration Path**:
- Keep `RecordEntity` as a specialized view of `InformationItem`
- Add `domain` field to existing records (default: 'health')
- Map `type` → `category` for health domain
- Existing code continues to work with `RecordEntity`

#### 1.2 Create Domain Registry

```dart
// lib/core/domain/domain_registry.dart
class DomainDefinition {
  final String id;              // 'health', 'notes', 'projects'
  final String name;            // 'Health Records'
  final String icon;            // Icon identifier
  final Color primaryColor;
  final List<CategoryDefinition> categories;
  final Map<String, FieldDefinition> customFields;
  final bool isEnabled;
}

class DomainRegistry {
  // Built-in domains
  static final health = DomainDefinition(...);
  static final notes = DomainDefinition(...);
  static final projects = DomainDefinition(...);
  
  // User-enabled domains
  List<DomainDefinition> getEnabledDomains();
  void enableDomain(String domainId);
  void disableDomain(String domainId);
}
```

#### 1.3 Extend Storage Layer

**Update Isar Schema**:
```dart
@collection
class Item {
  Id id = Isar.autoIncrement;
  late String domain;           // NEW: domain identifier
  late String category;         // was 'type'
  late DateTime date;
  late String title;
  String? content;              // was 'text'
  List<String> tags = [];
  String? customFieldsJson;     // NEW: flexible data
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
  
  @Index(composite: [CompositeIndex('category'), CompositeIndex('date')])
  String get domainCategoryDateIndex => '$domain-$category';
}
```

**Migration Strategy**:
1. Add new fields with defaults
2. Migrate existing records: `domain='health'`, `category=type`
3. Keep backward compatibility layer
4. Gradually phase out old terminology

#### 1.4 Update Core Services

**Generalize Repository**:
```dart
// lib/core/application/ports/item_repository.dart
abstract class ItemRepository {
  Future<InformationItem> create(InformationItem item);
  Future<InformationItem?> findById(int id);
  Future<List<InformationItem>> findByDomain(String domain, {
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int? limit,
    int? offset,
  });
  Future<void> update(InformationItem item);
  Future<void> delete(int id);
  Stream<List<InformationItem>> watchByDomain(String domain);
}
```

**Adapter Pattern**:
```dart
// Keep existing RecordsRepository as adapter
class RecordsRepository implements ItemRepository {
  // Delegates to ItemRepository with domain='health'
  // Provides backward compatibility
}
```

### Phase 2: Domain Expansion (Months 3-4)

**Goal**: Add 2-3 new domains while keeping health as the primary, fully-featured domain.

#### 2.1 Implement Core Domains

**Health Domain** (existing, enhanced):
- Categories: Visit, Lab, Medication, Note, Symptom, Vital
- Custom fields: Provider, Facility, Prescription details
- Specialized workflows: Vitals capture, medication reminders

**Personal Notes Domain** (new):
- Categories: Quick Note, Journal Entry, Idea, To-Do, Reference
- Custom fields: Mood, Energy level, Related items
- Workflows: Voice notes, quick capture, daily journal

**Projects Domain** (new):
- Categories: Project, Task, Milestone, Resource, Meeting
- Custom fields: Status, Priority, Due date, Assignee
- Workflows: Project templates, task lists, progress tracking

**Contacts Domain** (new):
- Categories: Personal, Professional, Emergency, Healthcare Provider
- Custom fields: Phone, Email, Address, Relationship, Notes
- Workflows: Quick dial, message, share information

#### 2.2 Domain-Aware UI

**Navigation Updates**:
```dart
// Bottom navigation or drawer
- Home (shows active domain)
- Domains (switch between enabled domains)
- Add (context-aware based on active domain)
- Search (cross-domain or filtered)
- Settings
```

**Domain Switcher**:
- Prominent domain selector in app bar
- Shows enabled domains with icons and colors
- Quick switch between contexts
- Badge showing item counts per domain

**Adaptive Screens**:
- List view adapts to domain (different card layouts)
- Add/Edit forms show domain-specific fields
- Search filters adapt to domain categories
- Detail view shows relevant metadata

#### 2.3 Domain Templates

**Template System**:
```dart
class DomainTemplate {
  final String domainId;
  final String name;
  final String description;
  final Map<String, dynamic> defaultValues;
  final List<FieldDefinition> fields;
  final WorkflowDefinition? workflow;
}

// Examples:
- Health: "Doctor Visit" template
- Notes: "Daily Journal" template
- Projects: "Software Project" template
- Contacts: "Healthcare Provider" template
```

### Phase 3: Personalization & Intelligence (Months 5-6)

**Goal**: Enable users to customize domains and leverage AI across all life areas.

#### 3.1 Custom Domains

**User-Defined Domains**:
- Create new domains from scratch
- Define custom categories
- Add custom fields with types (text, number, date, choice, etc.)
- Choose icons and colors
- Set default templates

**Domain Marketplace** (future):
- Community-contributed domain templates
- Import/export domain definitions
- Share custom domains with others

#### 3.2 Cross-Domain Intelligence

**AI Capabilities**:
```dart
class UniversalAIService {
  // Input processing
  Future<InformationItem> processCapture(
    CaptureArtifact artifact,
    String domain,
  );
  
  // Organization
  Future<List<String>> suggestTags(InformationItem item);
  Future<String> suggestCategory(InformationItem item);
  
  // Discovery
  Future<List<InformationItem>> findRelated(InformationItem item);
  Future<List<Connection>> detectConnections(String domain);
  
  // Insights
  Future<List<Insight>> generateInsights(String domain);
  Future<String> summarize(List<InformationItem> items);
}
```

**Cross-Domain Features**:
- "This recipe uses ingredients from your shopping list"
- "You last visited this doctor 6 months ago"
- "Your health symptoms correlate with stress at work"
- "You wanted to follow up on this idea from last month"

#### 3.3 Adaptive Interface

**Personalization**:
- Learn user's organizational preferences
- Suggest relevant categories and tags
- Customize views per domain
- Adapt workflows to usage patterns

**Context Awareness**:
- Show relevant domains based on time/location
- Suggest actions based on recent activity
- Proactive reminders and connections
- Smart search across domains

### Phase 4: Platform Maturity (Months 7-12)

**Goal**: Rich ecosystem with advanced capabilities.

#### 4.1 Advanced Features

**Relationships & Connections**:
- Link items across domains
- Visualize connections
- Timeline view across all domains
- Graph view of related items

**Collaboration** (optional):
- Share specific domains with others
- Collaborative projects
- Family health records
- Team workspaces

**Advanced Search**:
- Natural language queries
- Semantic search across domains
- Saved searches and views
- Custom filters and sorting

#### 4.2 Ecosystem

**Integrations**:
- Import from various sources
- Export to different formats
- API for third-party apps
- Automation and workflows

**Extensions**:
- Plugin system for custom domains
- Custom capture modes
- Custom AI processors
- Custom visualizations

## Implementation Priorities

### Immediate (Next 2 Weeks)

1. **Create Universal Data Model**
   - Define `InformationItem` entity
   - Create `DomainDefinition` structure
   - Design migration strategy

2. **Update Storage Layer**
   - Add `domain` and `customFieldsJson` to schema
   - Create migration script
   - Test backward compatibility

3. **Build Domain Registry**
   - Implement health domain definition
   - Create domain management service
   - Add domain enable/disable logic

### Short Term (Months 1-2)

1. **Generalize Core Services**
   - Create `ItemRepository` interface
   - Adapt existing `RecordsRepository`
   - Update use cases to be domain-aware

2. **Update UI Layer**
   - Add domain switcher to navigation
   - Make list/detail views domain-aware
   - Update add/edit forms for flexibility

3. **Implement First New Domain**
   - Create "Personal Notes" domain
   - Build note-specific UI
   - Test cross-domain functionality

### Medium Term (Months 3-4)

1. **Add More Domains**
   - Projects domain
   - Contacts domain
   - Test multi-domain workflows

2. **Enhance AI Layer**
   - Make AI domain-agnostic
   - Add cross-domain insights
   - Implement relationship detection

3. **Improve UX**
   - Domain onboarding flow
   - Quick domain switching
   - Cross-domain search

### Long Term (Months 5-12)

1. **Custom Domains**
   - User-defined domains
   - Custom fields and templates
   - Domain marketplace

2. **Advanced Features**
   - Relationship visualization
   - Timeline across domains
   - Advanced search and filters

3. **Ecosystem**
   - Integrations and imports
   - Plugin system
   - API for extensions

## Technical Considerations

### Backward Compatibility

**Critical**: Existing health records must continue to work seamlessly.

**Strategy**:
1. Add new fields with defaults
2. Keep `RecordEntity` as a view layer
3. Maintain existing APIs during transition
4. Gradual migration of terminology
5. Comprehensive testing at each step

### Performance

**Concerns**:
- Multiple domains in single database
- Cross-domain queries
- Large datasets with custom fields

**Solutions**:
- Proper indexing (`domain-category-date`)
- Lazy loading of custom fields
- Domain-specific caching
- Pagination and virtualization

### Data Migration

**Approach**:
```dart
class UniversalizationMigration {
  Future<void> migrate() async {
    // 1. Add new fields to schema
    // 2. Set domain='health' for all existing records
    // 3. Copy type → category
    // 4. Migrate any health-specific data to customFields
    // 5. Update indexes
    // 6. Verify data integrity
  }
}
```

### Testing Strategy

**Levels**:
1. **Unit Tests**: Domain entities, validation, business rules
2. **Integration Tests**: Repository operations, migrations
3. **UI Tests**: Domain switching, multi-domain workflows
4. **Migration Tests**: Data integrity, backward compatibility
5. **Performance Tests**: Large datasets, cross-domain queries

## Success Metrics

### Phase 1 (Foundation)
- ✅ Universal data model implemented
- ✅ Health domain migrated without data loss
- ✅ All existing features work unchanged
- ✅ New domain can be added in < 1 day

### Phase 2 (Expansion)
- ✅ 3+ domains available
- ✅ Users can enable/disable domains
- ✅ Domain-specific UI works correctly
- ✅ Cross-domain search functional

### Phase 3 (Intelligence)
- ✅ AI works across all domains
- ✅ Cross-domain connections detected
- ✅ Personalization adapts to usage
- ✅ Users report value from multiple domains

### Phase 4 (Maturity)
- ✅ Custom domains supported
- ✅ Rich ecosystem of integrations
- ✅ Community contributions active
- ✅ Platform scales to diverse use cases

## Risk Mitigation

### Technical Risks

**Risk**: Data migration fails or corrupts data
**Mitigation**: 
- Comprehensive backup before migration
- Rollback mechanism
- Extensive testing on copies
- Gradual rollout with feature flags

**Risk**: Performance degrades with multiple domains
**Mitigation**:
- Performance testing early
- Proper indexing strategy
- Lazy loading and caching
- Domain-specific optimizations

**Risk**: Backward compatibility breaks
**Mitigation**:
- Maintain adapter layers
- Comprehensive regression testing
- Gradual deprecation of old APIs
- Clear migration guides

### User Experience Risks

**Risk**: Existing users confused by changes
**Mitigation**:
- Gradual introduction of new concepts
- Clear onboarding for new features
- Health domain remains default
- Optional adoption of new domains

**Risk**: Complexity overwhelms simple use cases
**Mitigation**:
- Progressive disclosure
- Smart defaults
- Single-domain mode for simplicity
- Clear documentation and tutorials

## Next Steps

### Week 1-2: Planning & Design
1. Review this roadmap with stakeholders
2. Finalize universal data model design
3. Create detailed migration plan
4. Set up feature flags for gradual rollout

### Week 3-4: Foundation Implementation
1. Implement `InformationItem` entity
2. Create `DomainRegistry` system
3. Update Isar schema with new fields
4. Build and test migration script

### Week 5-6: Core Service Updates
1. Create `ItemRepository` interface
2. Adapt existing repositories
3. Update use cases for domain awareness
4. Comprehensive testing

### Week 7-8: UI Adaptation
1. Add domain switcher
2. Make views domain-aware
3. Update forms for flexibility
4. Polish and test

### Month 3: First New Domain
1. Implement "Personal Notes" domain
2. Build note-specific features
3. Test multi-domain workflows
4. Gather feedback

## Conclusion

This roadmap transforms the Patient App into a universal personal information system while:
- Preserving all existing functionality
- Maintaining data integrity
- Ensuring smooth user experience
- Building on strong foundations
- Enabling future growth

The health domain remains excellent and fully-featured, becoming the template for how other domains should work. The transition is gradual, tested, and reversible at each step.

**The vision is clear**: A personal information environment that grows with the user, adapts to their needs, and helps them make sense of their life, regardless of who they are or what they focus on.

