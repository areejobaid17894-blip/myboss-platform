# Squads — join, invitations, and admin

**Audience:** QA, developers  
**Runtime:** one API — `http://127.0.0.1:3001/api/v1` · Swagger: `http://127.0.0.1:3001/docs`

Default max members per squad is **5** (`maxUsersPerSquad` in employee settings).

---

## Seat reservation

Pending **join requests and invitations** both reserve a seat:

```
remainingSeats = maxUsersPerSquad − members.length − pendingRequests.length
```

Example: a squad with **1 member** can send at most **4** invitations, not 5. That keeps the squad from going over the limit if everyone accepts.

Canceling a pending invitation (leader or admin) frees the seat immediately.

---

## When a user joins

When someone **joins** a squad (leader accepts a join request, invitee accepts an invitation, they create a squad, or admin assigns them), the API **deletes all of that user’s join/invite rows** (`deleteUserJoinRequests`). Outstanding requests to other squads do not stay pending.

Accepting an invitation while already in another squad is rejected until they leave that squad.

---

## Leader invitations (employee app)

| Rule | Behaviour |
|------|-----------|
| Who can invite | Squad leader only |
| Who can be invited | Registered employees **not already in this squad** (including people in another squad) |
| Who cannot | Unregistered / not onboarded employees |
| Other-squad invitees | Shown with an “In {squad}” badge; they can accept only after leaving |
| Search | Name or email |
| Cancel | Leader can cancel a pending invite at any time |

Suggested-member directory still lists people when `remainingSeats` is 0; **Invite** is disabled until a seat is free.

Employee app: **My Squad** → open-slot rows, pending-invite list with Cancel, invite sheet.

| Method | Path | Who | Description |
|--------|------|-----|-------------|
| GET | `/squads/:id/suggested-members` | Leader | Directory + `remainingSeats`, `canInvite`, `inSquadName`, `invited` |
| POST | `/squads/:id/invites` | Leader | Send invite (`{ "userId": "…" }`) — uses one remaining seat |
| PUT | `/squads/:id/invites/:requestId` | Invitee | Accept or reject (`{ "action": "accepted" \| "rejected" }`) |
| DELETE | `/squads/:id/invites/:requestId` | Leader | Cancel pending invite and free the seat |
| POST | `/squads/:id/join` | Employee | Request to join |
| PUT | `/squads/:id/requests/:requestId` | Leader | Accept or reject a join request |

---

## Admin console

**Squads → Manage**

- Rename squad
- Remove members (not the current leader — transfer leadership first)
- **Make leader** (transfer leadership)
- Add a registered employee who is **not in a squad** (hard cap includes pending seats)
- Delete squad (members are unassigned)

**Invitations** (`/invitations`)

- Monitor leader invitations across squads
- Cancel a pending invitation (frees the seat)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/squads/admin/all` | Squads with members and remaining seats |
| GET | `/squads/admin/unassigned-employees` | Registered employees with no squad |
| GET | `/squads/admin/invites` | Leader invitations (pending + historical while rows still exist) |
| POST | `/squads/admin/assign` | Add unassigned employee |
| PUT | `/squads/admin/:id` | Rename |
| PUT | `/squads/admin/:id/leadership` | Transfer leadership `{ "newLeaderId": "…" }` |
| DELETE | `/squads/admin/:id/members/:memberId` | Remove member |
| DELETE | `/squads/admin/:id/invites/:requestId` | Cancel pending invite |
| DELETE | `/squads/admin/:id` | Delete squad |

Accepted invitations may not appear in admin history because joining **deletes** that user’s request rows.

---

## QA checks

- [ ] 1-member squad: Invite disabled after 4 pending invites
- [ ] Cancel invite → seat returns → can invite someone else
- [ ] Accept join/invite → user’s other pending requests disappear
- [ ] Invitee already in another squad cannot accept until they leave
- [ ] Unregistered people cannot be invited
- [ ] Admin: rename, make leader, remove, add unassigned, delete, cancel invite

---

*Orange — my boss app*
