# Ensolvers Ops API — extracted endpoint catalog

Extracted from the frontend bundle (`main.2776d50b.js`, Aug 2026). Swagger is not
exposed (`/v3/api-docs` → 500), so this was mined from the SPA's service classes.

- **Base URL:** `https://ops-api.ensolvers.com`
- **Auth:** `Authorization: Bearer <token>` (grab from browser DevTools; format `xxx:yyy`)
- **Headers the app sends:** `Origin: https://ops.ensolvers.com`, `Referer: https://ops.ensolvers.com/`
- **Response envelope:** `{"message": "...", "success": true, "content": <payload>}`
- **Paginated content:** `{"totalElements", "totalPages", "first", "last", "size", "content": [...]}`

## Generic CRUD (every resource below)

| Verb   | Path                        | Notes |
|--------|-----------------------------|-------|
| GET    | `{base}/{resource}/{externalId}` | get one |
| GET    | `{base}/{resource}?page={p}&pageSize={n}` | paginated list |
| POST   | `{base}/{resource}`         | create (JSON body) |
| PUT    | `{base}/{resource}/{externalId}` | update (body includes `externalId`) |
| DELETE | `{base}/{resource}/{externalId}` | delete |

## Resources

```
/ensolvers-ops/work-log            /ensolvers-ops/work-log-weekly     /ensolvers-ops/work-log-monthly
/ensolvers-ops/assignation         /ensolvers-ops/assignation-pause   /ensolvers-ops/timeoff
/ensolvers-ops/holiday             /ensolvers-ops/projects            /ensolvers-ops/positions
/ensolvers-ops/properties          /ensolvers-ops/user-sites          /ensolvers-ops/documents
/ensolvers-ops/faqs                /ensolvers-ops/knowledge-base      /ensolvers-ops/accomplishment
/ensolvers-users                   /badges                            /anniversaries
```

## Custom endpoints by resource

Method names come from the frontend service classes; resource grouping is
best-effort from bundle context. `{id}` = externalId unless noted.

### work-log
| Verb | Path | Frontend method |
|------|------|-----------------|
| GET  | `/ensolvers-ops/work-log/weekly-hours?year=&month=&projectExternalId=` | getWorkLogsPerWeek |
| GET  | `/ensolvers-ops/work-log/getWorkLogs/{requesterId}?startDate=&endDate=` | findWorkLogsByRequesterAndDates |
| GET  | `/ensolvers-ops/work-log/assignation-workLogs/{assignationId}?month=` | findMonthWorkLogsByAssignationId |
| GET  | `/ensolvers-ops/work-log/find-by-position?positionExternalId=` | findByPositionExternalId |
| GET  | `/ensolvers-ops/work-log/unified-reports?userExternalId=&month=&year=` | getUnifiedReports |
| GET  | `/ensolvers-ops/work-log/external-report/{id}` | getWorklogExternalReport |
| PUT  | `/ensolvers-ops/work-log/adjust-hours` | adjustHours |
| POST | `/ensolvers-ops/work-log/{id}/send-internal-report` | sendInternalReportToSlack |
| POST | `/ensolvers-ops/work-log/{id}/send-external-report` | sendExternalReportToSlack |
| POST | `/ensolvers-ops/work-log/timeOff-worklogs/create/{id}` | createTimeOffWorklogs |
| POST | `/ensolvers-ops/work-log/timeOff-worklogs/delete/{id}` | deleteTimeOffWorklogs |

Work-log create payload (what the web app POSTs):
```json
{
  "hours": 8, "internalHours": 8, "adjustmentHours": 0, "bonusHours": 0,
  "shortDay": "2026-08-13T04:00:00.000Z",
  "assignationExternalId": "...", "assignationName": "699 - Hyros - Architect",
  "isWeekend": false, "isHoliday": false, "isPaused": false,
  "description": "...", "internalDescription": "...", "category": "REGULAR"
}
```

### work-log-weekly
| POST | `/ensolvers-ops/work-log-weekly/batch` | approveWeek / batchApproveWeeks |

### assignation
| Verb | Path | Frontend method |
|------|------|-----------------|
| GET  | `/ensolvers-ops/assignation/details/{id}` | getAssignationDetails |
| GET  | `/ensolvers-ops/assignation/projections?year=&month=&bonused=` | getAssignationProjection |
| GET  | `/ensolvers-ops/assignation/over-staff-projection` | getOverStaffProjection |
| GET  | `/ensolvers-ops/assignation/switch-assignation-builder/{from}/{to}` | getAssignationTransferBuilder |
| POST | `/ensolvers-ops/assignation/switch-assignation` | transferAssignation |
| GET  | `/ensolvers-ops/assignation/validate-position-date?positionExternalId=&assignationStartDate=&assignationEndDate=` | validateAssignationStartDate |

### assignation-pause
| GET    | `/ensolvers-ops/assignation-pause/by-assignation?assignationExternalId=` | findByAssignation |
| GET    | `/ensolvers-ops/assignation-pause/paused-days?assignationExternalId=&year=&month=` | getPausedDays |
| POST   | `/ensolvers-ops/assignation-pause` | createPause |
| DELETE | `/ensolvers-ops/assignation-pause/{id}` | deletePause |

### timeoff
| GET | `/ensolvers-ops/timeoff/getTimeOffs?assignationExternalId=&year=&month=` | findTimeOffsByRequesterAndDate |
| GET | `/ensolvers-ops/timeoff/get-requester-timeoff?externalId=` | getRequesterTimeOff |
| GET | `/ensolvers-ops/timeoff/report?year=&month=&page=&pageSize=&remainingVacancies=&searchFilter=` | getTimeOffReport |
| GET | `/ensolvers-ops/timeoff/vacation-report?year=&month=&page=&pageSize=&remainingVacancies=&searchFilter=` | getVacationReport |

### holiday
| GET | `/ensolvers-ops/holiday/month/{month}?country=` | findHolidaysOfMonthByCountry |

### projects
| GET    | `/ensolvers-ops/projects/projects-names` | findProjectNames |
| GET    | `/ensolvers-ops/projects/projects-names/{internal}` | findProjectNamesByInternal |
| GET    | `/ensolvers-ops/projects/projects-names-by?onlyExternal=&assigned=` | findAllProjectsNames |
| GET    | `/ensolvers-ops/projects/all/filtered?page=&pageSize=&archived=&projectType=` | findAll |
| GET    | `/ensolvers-ops/projects/timeline?{query}` | getTimeline |
| POST   | `/ensolvers-ops/projects/manager/{projectId}/{userId}` | addManagerToProject |
| DELETE | `/ensolvers-ops/projects/manager/{projectId}/{userId}` | removeManagerFromProject |
| GET    | `/ensolvers-ops/projects/manager/check/{projectId}/{userId}` | isUserManagerFromProject |
| GET    | `/ensolvers-ops/projects/manager/check-core/{projectId}/{userId}` | isUserCoreManagerFromProject |
| GET    | `/ensolvers-ops/projects/manager/check-core-by-assignation/{projectId}/{assignationId}` | isUserCoreManagerFromProjectByAssignation |
| GET    | `/ensolvers-ops/projects/manager/get/{projectId}` | getManagerListFromProject |
| GET    | `/ensolvers-ops/projects/manager/get-projects` | getProjectsFromManager |
| GET    | `/ensolvers-ops/projects/manager/projects-names` | findProjectsNamesByUserManagerExternalId |

### positions
| GET | `/ensolvers-ops/positions/position-names?projectExternalId=&startDate=` | findPositionNamesByProjectId |
| GET | `/ensolvers-ops/positions/assigned-to` | findProjectUserListFromManager |
| GET | `/ensolvers-ops/positions/{id}` | findPositionByExternalId |

### ensolvers-users
| GET | `/ensolvers-users/user-names` | findUserNames |
| GET | `/ensolvers-users/manager-user-names` | findManagerUserNames |
| PUT | `/ensolvers-users/{id}/change-status?enable=` | changeUserStatus |
| GET | `/ensolvers-users/user-core/{coreUserId}` | findByCoreUserId |
| GET | `/ensolvers-users/{id}/project-positions` | getProjectPositions |
| GET | `/ensolvers-users/over-staff-report?year=&month=&filter=&role=` | getOverStaffReport |
| GET | `/ensolvers-users/get-information?externalId=` | getMissingInformation |
| GET | `/ensolvers-users/get-dashboard` | getDashboard |
| GET | `/ensolvers-users/get-available-staff?year=&month=` | getAvailableStaff |
| PUT | `/ensolvers-users/self/regenerate-drata-identifier` | regenerateDrataIdentifier |
| PUT | `/ensolvers-users/regenerate-drata-identifier?externalId=` | regenerateDrataIdentifierByAdmin |

### accomplishment
| GET    | `/ensolvers-ops/accomplishment/my-accomplishments?page=&pageSize=` | getMyAccomplishments |
| GET    | `/ensolvers-ops/accomplishment/status?page=&pageSize=&status=` | getAllAccomplishmentsByStatus |
| POST   | `/ensolvers-ops/accomplishment/create?reporterId=` | createAccomplishment |
| PUT    | `/ensolvers-ops/accomplishment/{id}` | updateAccomplishment |
| DELETE | `/ensolvers-ops/accomplishment/{id}` | deleteAccomplishment |
| PUT    | `/ensolvers-ops/accomplishment/status?externalId=&status=` | updateStatus |
| GET    | `/ensolvers-ops/accomplishment/monthly-total-points` | getMonthlyTotalPoints |
| GET    | `/ensolvers-ops/accomplishment/monthly-ranking?month=&year=&category=` | getMonthlyRanking |
| GET    | `/ensolvers-ops/accomplishment/types` | getTypes |

### badges / certifications
| POST | `/badges/upload-limit/{n}` | uploadImageToBackend |
| GET  | `/badges/ops-user/{id}` | getFormData |
| GET  | `/badges/ops-user/paged/{id}?page=&pageSize=` | getBadgesPagedForOpsUser |
| GET  | `/badges/available` | getAvailableBadgesForOpsUser |
| GET  | `/badges/badges-names?active=` | findAllBadgesNames |
| PUT  | `/badges/update/{id}` | editBadge |
| PUT  | `/badges/{id}/change-status?enable=` | changeBadgeStatus |
| POST | `/badges/badges/{id}/start-certification` | apply |
| GET  | `/badges/filtered?page=&pageSize=&badgeExternalId=&search=&status=&level=` | findFiltered |
| POST | `/badges/create` | createCertification |
| PUT  | `/badges/status?certificationId=&status=` | changeStatus |

### knowledge-base / user-sites / misc
| GET | `/ensolvers-ops/knowledge-base/knowledge-base-categories` | findKnowledgeBaseCategories |
| GET | `/ensolvers-ops/knowledge-base/knowledge-base-codes` | findKnowledgeBaseCodes |
| PUT | `/ensolvers-ops/user-sites/update/{id}` | editSite |

### auth (unauthenticated flows)
```
POST /auth/login-code            POST /auth/login-with-code       POST /auth/sign-up
POST /auth/forgot-password       POST /auth/validate-forgot-password
POST /auth/update-password       GET  /oauth/connect/google       GET /oauth/logout
```
