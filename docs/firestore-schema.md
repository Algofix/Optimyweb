# Optimyweb — Firestore schema

## Collections

### `projects` (top level)

Each document is one site or initiative you are optimizing.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Short title (e.g. "Piera town website") |
| `url` | string? | Site URL, optional |
| `goal` | string | What you want to improve |
| `status` | string | `draft` \| `active` \| `done` |
| `priority` | number | 1 = highest (sort ascending) |
| `createdAt` | timestamp | Set on create |
| `updatedAt` | timestamp | Updated on every save |

**Example document**

```json
{
  "name": "Optimyweb landing",
  "url": "https://example.com",
  "goal": "Improve LCP and mobile layout",
  "status": "active",
  "priority": 1,
  "createdAt": "<server timestamp>",
  "updatedAt": "<server timestamp>"
}
```

### `projects/{projectId}/tasks` (subcollection)

Checklist items per project.

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Task label |
| `done` | boolean | Completed or not |
| `createdAt` | timestamp | Set on create |

---

## Storage (later)

Path pattern for attachments:

```
projects/{projectId}/attachments/{fileName}
```

Store only metadata in Firestore if needed; files live in Storage.

---

## Suggested security rules (development)

Replace with stricter rules before production. Requires Firebase Auth later.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /projects/{projectId} {
      allow read, write: if true;
      match /tasks/{taskId} {
        allow read, write: if true;
      }
    }
  }
}
```

---

## Screen map

| Screen | Route / entry | Data |
|--------|----------------|------|
| Home | App start | Lists `projects`, filter by status |
| Project detail | Tap a project | Project fields + live `tasks` list |
| New / edit project | FAB or edit icon | Writes `projects` doc |
| Add task | Detail FAB | Writes `tasks` subcollection |
