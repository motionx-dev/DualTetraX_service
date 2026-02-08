# DualTetraX Services - Development Roadmap

**Version**: 1.0
**Date**: 2026-02-08

---

## Phase 1: MVP (Months 1-2) - Core Features

### Week 1-2: Infrastructure Setup
- [x] Supabase project creation
- [x] Database schema design (pii + analytics separation)
- [x] RLS policies setup
- [ ] Vercel project setup
- [ ] Environment variables configuration
- [ ] CI/CD pipeline (GitHub Actions)

### Week 3-4: Authentication & User Management
- [ ] Email/password authentication (Supabase Auth)
- [ ] Social login (Google, Apple)
- [ ] Korean social login (Naver, Kakao)
- [ ] Password reset (Email + SMS via Kakao)
- [ ] User profile CRUD
- [ ] Privacy consent management (with timestamps)

### Week 5-6: Device Management
- [ ] Device registration API
- [ ] Device ownership management
- [ ] Device list/detail API
- [ ] BLE device pairing (mobile app)
- [ ] Device heartbeat tracking

### Week 7-8: Usage Data Collection
- [ ] Usage session upload API (batch)
- [ ] Offline sync mechanism (mobile app)
- [ ] Daily statistics aggregation (cron job)
- [ ] Session list/detail API
- [ ] Data deduplication (local_session_id)

---

## Phase 2: Analytics & Personalization (Month 3)

### Week 9-10: Statistics & Reporting
- [ ] Daily/weekly/monthly statistics API
- [ ] Usage pattern analysis (shot type, mode, level)
- [ ] Time-of-day analysis
- [ ] Export to CSV/PDF
- [ ] Timezone handling (user's local time)
- [ ] Weather/humidity data integration (location-based)

### Week 11-12: Personalization Engine
- [ ] Skin profile management
- [ ] User goals (weekly sessions, daily duration)
- [ ] AI-based recommendations (simple algorithm)
- [ ] Usage reminders (push notifications)
- [ ] Weather-based recommendations (e.g., "High UV today, use protection mode")

---

## Phase 3: OTA Firmware Management (Month 4)

### Week 13-14: Firmware Management
- [ ] Firmware upload (admin)
- [ ] Firmware versioning system
- [ ] Firmware storage (Supabase Storage)
- [ ] Checksum verification (SHA256)
- [ ] Firmware rollout strategies (all, gradual, beta, manual)

### Week 15-16: OTA Updates
- [ ] Check for updates API
- [ ] Download firmware (mobile app)
- [ ] BLE firmware transfer (mobile app)
- [ ] Update status reporting
- [ ] Update history tracking (per-user)
- [ ] Rollback mechanism

---

## Phase 4: Admin Console (Month 5)

### Week 17-18: Admin Dashboard
- [ ] User management (list, search, detail)
- [ ] Device management (list, filter, search)
- [ ] System metrics dashboard (DAU, MAU, devices, sessions)
- [ ] Firmware distribution chart
- [ ] Update success rate tracking

### Week 19-20: Admin Tools
- [ ] Firmware upload UI
- [ ] Rollout management UI
- [ ] User search (email, name, device serial)
- [ ] Device tagging (beta, VIP)
- [ ] Audit logs viewer
- [ ] Export data (CSV)

---

## Phase 5: Web Frontend (Month 6)

### Week 21-22: User Dashboard (Web)
- [ ] User authentication (web)
- [ ] Profile management
- [ ] Device list/detail
- [ ] Usage statistics (charts)
- [ ] Timezone selection
- [ ] Responsive design (mobile/desktop)
- [ ] Dark mode

### Week 23-24: Landing Page
- [ ] Product introduction
- [ ] App download links (iOS, Android)
- [ ] User reviews
- [ ] FAQ
- [ ] Contact form
- [ ] SEO optimization

---

## Phase 6: Security & Compliance (Ongoing)

### Month 1-6 (Continuous)
- [ ] GDPR compliance (data export, deletion)
- [ ] Data separation (PII vs analytics)
- [ ] Row Level Security (RLS) enforcement
- [ ] Audit logging (all PII access)
- [ ] Rate limiting
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Password policy enforcement
- [ ] Privacy consent management
- [ ] Location data consent management

---

## Phase 7: Testing & Optimization (Month 7)

### Week 25-26: Testing
- [ ] Unit tests (backend functions)
- [ ] Integration tests (API endpoints)
- [ ] Mobile app testing (iOS + Android)
- [ ] Web app testing (Chrome, Safari, Firefox)
- [ ] Load testing (100 concurrent users)
- [ ] Security audit (penetration testing)

### Week 27-28: Performance Optimization
- [ ] Database query optimization (indexes, EXPLAIN)
- [ ] API response time optimization (< 200ms p95)
- [ ] Mobile app offline sync optimization
- [ ] BLE transfer speed optimization
- [ ] Image optimization (profile images)
- [ ] Lazy loading (web frontend)

---

## Phase 8: Launch Preparation (Month 8)

### Week 29-30: Beta Testing
- [ ] Beta tester recruitment (50 users)
- [ ] Beta feedback collection
- [ ] Bug fixes
- [ ] UX improvements

### Week 31-32: Production Launch
- [ ] Production deployment (Vercel + Supabase)
- [ ] Monitoring setup (Sentry, CloudWatch)
- [ ] Documentation finalization
- [ ] App store submission (iOS + Android)
- [ ] Marketing materials
- [ ] Press release
- [ ] Customer support setup

---

## Future Enhancements (Post-Launch)

### Phase 9: Advanced Features (Month 9-12)
- [ ] AI skin diagnosis (camera-based)
- [ ] Before/after photo comparison
- [ ] Community features (reviews, Q&A)
- [ ] Premium subscription model
- [ ] Multi-language support (English, Japanese, Chinese)
- [ ] B2B features (beauty salons, clinics)
- [ ] Expert consultation booking
- [ ] Wearable device integration (Apple Watch)
- [ ] Weather-based usage recommendations (enhanced)
- [ ] Location-based humidity/UV index tracking

---

## Success Metrics (3 Months Post-Launch)

### User Metrics
- [ ] 500+ registered users
- [ ] 70%+ Monthly Active Users (MAU)
- [ ] 3+ average weekly usage sessions
- [ ] 4.0+ user satisfaction rating (out of 5)

### Technical Metrics
- [ ] 99.9%+ uptime
- [ ] < 200ms API response time (p95)
- [ ] 99%+ data sync success rate
- [ ] 95%+ OTA update success rate
- [ ] < 1% mobile app crash rate

### Business Metrics
- [ ] < $50/month operating cost (early stage)
- [ ] User acquisition cost < $10/user
- [ ] User retention rate > 60% (30-day)

---

## Resource Allocation

### Development Team (Initial)
- 1x Full-stack Developer (Backend + Frontend)
- 0.5x Mobile Developer (Flutter, part-time)
- 0.5x DevOps/SRE (part-time, infrastructure)

### Infrastructure Costs (Monthly)
- Supabase Pro: $25
- Vercel Pro: $20
- Domain + SSL: $5
- Total: ~$50/month (early stage)

---

## Risk Management

| Risk | Impact | Mitigation |
|------|--------|------------|
| Database breach | High | Data separation, encryption, audit logs |
| OTA update failure | Medium | Gradual rollout, rollback mechanism |
| BLE transfer failure | Medium | Retry logic, user guidance |
| Supabase outage | High | Backup plan (migration to AWS) |
| Low user adoption | High | User feedback loop, UX iteration |
| High costs at scale | Medium | Monitor usage, optimize queries, consider AWS migration |

---

## Decision Points

### Month 3: Evaluate Supabase vs AWS
- **If** database size > 5GB or costs > $100/month → Consider AWS migration
- **If** Supabase limitations encountered → Plan migration

### Month 6: Evaluate Premium Features
- **If** user engagement is high → Launch premium subscription
- **If** users request advanced features → Prioritize in Phase 9

---

**Document End**
