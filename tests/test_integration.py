"""Quick integration test for the unified app."""
import requests

API = 'http://127.0.0.1:5000/api'
results = []

def test(name, fn):
    try:
        result = fn()
        results.append((name, 'PASS', result))
        print(f'  [PASS] {name}: {result}')
    except Exception as e:
        results.append((name, 'FAIL', str(e)))
        print(f'  [FAIL] {name}: {e}')

print('=== Civic Grievance System — Integration Tests ===\n')

# 1. Health
test('Health Check', lambda: requests.get('http://127.0.0.1:5000/health', timeout=5).json()['status'])

# 2. Register
test('Register Citizen', lambda: requests.post(f'{API}/auth/register', json={
    'name': 'TestCitizen', 'email': 'tc@test.com', 'phone': '9999',
    'username': 'testcitizen', 'password': 'pass123'
}, timeout=5).json().get('success') or 'already exists')

# 3. Login citizen
test('Login Citizen', lambda: requests.post(f'{API}/auth/login', json={
    'username': 'testcitizen', 'password': 'pass123'
}, timeout=5).json()['user']['role'])

# 4. Login admin
test('Login Admin', lambda: requests.post(f'{API}/auth/login', json={
    'username': 'admin', 'password': 'admin123'
}, timeout=5).json()['user']['role'])

# 5. Submit complaint
def submit_complaint():
    r = requests.post(f'{API}/complaints', json={
        'name': 'TestCitizen', 'email': 'tc@test.com', 'phone': '9999',
        'category': 'electricity', 'location': 'Main Road',
        'description': 'Power outage affecting many homes', 'username': 'testcitizen'
    }, timeout=20)
    d = r.json()
    return f"id={d['complaint_id']}, priority={d['priority']}, fuzzy={d['fuzzy_score']}, dept={d['department']}"

test('Submit Complaint + Fuzzy Priority', submit_complaint)

# 6. Get complaint ID from results
cid = [r[2] for r in results if r[0] == 'Submit Complaint + Fuzzy Priority'][0].split('id=')[1].split(',')[0]

# 7. My complaints
test('My Complaints', lambda: f"{len(requests.get(f'{API}/complaints/mine?username=testcitizen', timeout=5).json())} found")

# 8. Admin status update
test('Admin Status Update', lambda: requests.put(f'{API}/complaints/{cid}/status', json={
    'status': 'in-progress', 'notes': 'Under investigation'
}, timeout=5).json()['new_status'])

# 9. Get complaint detail with timeline
def get_detail():
    c = requests.get(f'{API}/complaints/{cid}', timeout=5).json()
    return f"status={c['status']}, fuzzy={c['fuzzy_priority_score']}, history={len(c['history'])} entries"
test('Complaint Detail + Timeline', get_detail)

# 10. Analytics
def get_analytics():
    a = requests.get(f'{API}/analytics/summary', timeout=5).json()
    prio = ','.join([f"{p['priority']}:{p['count']}" for p in a.get('by_priority', [])])
    return f"total={a['total']}, high_prio={a.get('high_priority')}, priorities=[{prio}]"
test('Analytics Summary', get_analytics)

# Summary
passed = sum(1 for r in results if r[1] == 'PASS')
total = len(results)
print(f'\n{"="*50}')
print(f'Results: {passed}/{total} tests passed')
if passed == total:
    print('[PASS] ALL TESTS PASS!')
else:
    print('[FAIL] Some tests failed')
