import React, { useState, useEffect } from 'react';

function App() {
  const [stats, setStats] = useState(null);
  const [requests, setRequests] = useState([]);
  const [connected, setConnected] = useState(false);
  const [stressThreads, setStressThreads] = useState(2);
  const [stressDuration, setStressDuration] = useState(30);
  const [isSimulatingTraffic, setIsSimulatingTraffic] = useState(false);

  // Fetch status metrics and recent request history
  const fetchData = async () => {
    try {
      const statsRes = await fetch('/api/status');
      if (!statsRes.ok) throw new Error('Status not OK');
      const statsData = await statsRes.json();
      setStats(statsData);
      setConnected(true);

      const reqRes = await fetch('/api/requests');
      if (reqRes.ok) {
        const reqData = await reqRes.json();
        setRequests(reqData);
      }
    } catch (err) {
      console.error('Error fetching backend metrics:', err);
      setConnected(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 2000);
    return () => clearInterval(interval);
  }, []);

  // Formatter for Uptime
  const formatUptime = (seconds) => {
    if (!seconds) return '0s';
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    const parts = [];
    if (hrs > 0) parts.push(`${hrs}h`);
    if (mins > 0) parts.push(`${mins}m`);
    if (secs > 0 || parts.length === 0) parts.push(`${secs}s`);
    return parts.join(' ');
  };

  // Trigger Backend Stress Test
  const handleStartStress = async () => {
    try {
      const res = await fetch('/api/stress', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ threads: stressThreads, duration: stressDuration }),
      });
      if (res.ok) {
        fetchData();
      }
    } catch (err) {
      console.error('Error starting stress:', err);
    }
  };

  // Stop Backend Stress Test
  const handleStopStress = async () => {
    try {
      const res = await fetch('/api/stress/stop', {
        method: 'POST',
      });
      if (res.ok) {
        fetchData();
      }
    } catch (err) {
      console.error('Error stopping stress:', err);
    }
  };

  // Simulate High Request Traffic Burst (makes 40 quick parallel requests to see active logging)
  const handleSimulateTraffic = async () => {
    if (isSimulatingTraffic) return;
    setIsSimulatingTraffic(true);
    
    const requestsToMake = 40;
    const promises = [];
    
    for (let i = 0; i < requestsToMake; i++) {
      promises.push(
        fetch('/api/status?burst=' + i).catch((e) => console.log('Burst request failed', e))
      );
    }

    await Promise.all(promises);
    setIsSimulatingTraffic(false);
    fetchData();
  };

  return (
    <div className="app-container">
      <header>
        <div className="brand-section">
          <div className="logo-icon">🚀</div>
          <div>
            <h1>Intelligent Auto-Scaling Dashboard</h1>
            <div className="subtitle">Container-level scaling monitor & load generator</div>
          </div>
        </div>
        <div className={`connection-status ${connected ? '' : 'disconnected'}`}>
          <span className="status-dot"></span>
          {connected ? 'CONNECTED TO CONTAINER' : 'DISCONNECTED'}
        </div>
      </header>

      {stats ? (
        <div className="dashboard-grid">
          {/* Hardware & System Performance metrics */}
          <div className="card col-8">
            <h2 className="card-title">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                <line x1="6" y1="6" x2="6.01" y2="6"></line>
                <line x1="6" y1="18" x2="6.01" y2="18"></line>
              </svg>
              Live Resource Utilization
            </h2>
            <div className="gauge-container">
              {/* CPU Meter */}
              <div className="gauge-wrapper">
                <div className="gauge-header">
                  <span className="gauge-title">CPU Utilization</span>
                  <span className="gauge-pct">{stats.cpu.usagePercent}%</span>
                </div>
                <div className="gauge-bar-outer">
                  <div 
                    className={`gauge-bar-inner ${stats.cpu.usagePercent > 70 ? 'high' : ''}`}
                    style={{ width: `${stats.cpu.usagePercent}%` }}
                  ></div>
                </div>
              </div>

              {/* Memory Meter */}
              <div className="gauge-wrapper">
                <div className="gauge-header">
                  <span className="gauge-title">Memory Allocation ({stats.memory.usedGB} / {stats.memory.totalGB} GB)</span>
                  <span className="gauge-pct">{stats.memory.usagePercent}%</span>
                </div>
                <div className="gauge-bar-outer">
                  <div 
                    className={`gauge-bar-inner ${stats.memory.usagePercent > 80 ? 'high' : ''}`}
                    style={{ width: `${stats.memory.usagePercent}%` }}
                  ></div>
                </div>
              </div>
            </div>
            
            <div style={{ marginTop: '1.5rem', paddingTop: '1rem', borderTop: '1px solid rgba(255,255,255,0.05)' }}>
              <div className="metric-row" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem' }}>
                <div>
                  <div className="metric-label" style={{ marginBottom: '0.25rem' }}>CPU Model</div>
                  <div className="metric-value" style={{ textAlign: 'left', fontWeight: '500' }}>{stats.cpu.model}</div>
                </div>
                <div>
                  <div className="metric-label" style={{ marginBottom: '0.25rem' }}>Cores Count</div>
                  <div className="metric-value" style={{ textAlign: 'left', fontWeight: '500' }}>{stats.cpu.cores} Cores</div>
                </div>
              </div>
            </div>
          </div>

          {/* Instance General Info Panel */}
          <div className="card col-4">
            <h2 className="card-title">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
                <line x1="8" y1="21" x2="16" y2="21"></line>
                <line x1="12" y1="17" x2="12" y2="21"></line>
              </svg>
              Container Info
            </h2>
            <div className="metric-row">
              <div className="metric-item">
                <span className="metric-label">Hostname</span>
                <span className="metric-value highlight">{stats.hostname}</span>
              </div>
              <div className="metric-item">
                <span className="metric-label">Node Runtime</span>
                <span className="metric-value">{stats.nodeVersion}</span>
              </div>
              <div className="metric-item">
                <span className="metric-label">Host OS</span>
                <span className="metric-value">{stats.platform}</span>
              </div>
              <div className="metric-item">
                <span className="metric-label">Uptime</span>
                <span className="metric-value">{formatUptime(stats.uptime)}</span>
              </div>
            </div>
          </div>

          {/* CPU Load Generator Simulation */}
          <div className="card col-6">
            <h2 className="card-title">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
              </svg>
              Auto-Scaling Stress Test
            </h2>
            <div className="simulator-panel">
              {!stats.stressTest.active ? (
                <>
                  <div className="slider-group">
                    <div className="slider-labels">
                      <span className="slider-label">Stressing Threads (CPUs)</span>
                      <span className="slider-val">{stressThreads}</span>
                    </div>
                    <input 
                      type="range" 
                      min="1" 
                      max={Math.max(4, stats.cpu.cores)} 
                      value={stressThreads}
                      onChange={(e) => setStressThreads(parseInt(e.target.value))}
                    />
                  </div>

                  <div className="slider-group">
                    <div className="slider-labels">
                      <span className="slider-label">Test Duration (seconds)</span>
                      <span className="slider-val">{stressDuration}s</span>
                    </div>
                    <input 
                      type="range" 
                      min="10" 
                      max="120" 
                      step="5"
                      value={stressDuration}
                      onChange={(e) => setStressDuration(parseInt(e.target.value))}
                    />
                  </div>

                  <button className="btn btn-primary" onClick={handleStartStress}>
                    🚀 Start Stress Simulation
                  </button>
                </>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  <div className="stress-active-alert">
                    <div className="stress-alert-title">
                      ⚠️ CPU Stress Test Running
                    </div>
                    <div className="stress-alert-desc">
                      Currently running intensive mathematics calculations on {stats.stressTest.threads} execution thread(s) to simulate container processor loading.
                    </div>
                    <div style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--danger)', marginTop: '0.25rem' }}>
                      Time remaining: {Math.ceil(stats.stressTest.remainingMs / 1000)}s
                    </div>
                  </div>
                  
                  <button className="btn btn-danger" onClick={handleStopStress}>
                    ⏹️ Stop Simulation
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Traffic Simulator Panel */}
          <div className="card col-6">
            <h2 className="card-title">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
              Traffic Load Generator
            </h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', height: '100%', justifyContent: 'center' }}>
              <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', lineHeight: '1.5' }}>
                Trigger a burst of API requests to the Node.js backend. This will log network interactions in the requests monitor panel, showing latency and throughput load.
              </p>
              <button 
                className="btn btn-primary" 
                style={{ background: 'linear-gradient(135deg, var(--accent), var(--primary))', color: '#fff' }}
                onClick={handleSimulateTraffic}
                disabled={isSimulatingTraffic}
              >
                {isSimulatingTraffic ? (
                  <>Sending Burst Request Stream...</>
                ) : (
                  <>⚡ Send 40 Parallel Requests</>
                )}
              </button>
            </div>
          </div>

          {/* Live request logs */}
          <div className="card col-12">
            <h2 className="card-title">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="8" y1="6" x2="21" y2="6"></line>
                <line x1="8" y1="12" x2="21" y2="12"></line>
                <line x1="8" y1="18" x2="21" y2="18"></line>
                <line x1="3" y1="6" x2="3.01" y2="6"></line>
                <line x1="3" y1="12" x2="3.01" y2="12"></line>
                <line x1="3" y1="18" x2="3.01" y2="18"></line>
              </svg>
              Live API Gateway Requests ({requests.length})
            </h2>
            <div className="log-table-container">
              {requests.length > 0 ? (
                <table>
                  <thead>
                    <tr>
                      <th>Time</th>
                      <th>Method</th>
                      <th>Endpoint</th>
                      <th>Status</th>
                      <th>Server Latency</th>
                    </tr>
                  </thead>
                  <tbody>
                    {requests.map((r) => (
                      <tr key={r.id}>
                        <td style={{ color: 'var(--text-secondary)' }}>{r.timestamp}</td>
                        <td style={{ fontWeight: 600, color: r.method === 'POST' ? 'var(--accent)' : 'var(--primary)' }}>{r.method}</td>
                        <td style={{ fontFamily: 'monospace' }}>{r.url}</td>
                        <td>
                          <span className={`status-badge ${r.status >= 400 ? 'error' : r.status >= 300 ? 'info' : 'success'}`}>
                            {r.status}
                          </span>
                        </td>
                        <td style={{ fontWeight: 500 }}>{r.duration}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <div style={{ textAlign: 'center', padding: '2rem 0', color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                  No requests processed yet. Trigger traffic load above to see entries here.
                </div>
              )}
            </div>
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', alignItems: 'center', justifyContent: 'center', height: '50vh' }}>
          <div style={{ 
            width: '40px', 
            height: '40px', 
            border: '3px solid var(--panel-border)', 
            borderTopColor: 'var(--primary)', 
            borderRadius: '50%',
            animation: 'pulse-ring 1.2s linear infinite'
          }}></div>
          <div style={{ color: 'var(--text-secondary)', fontSize: '0.95rem' }}>
            Awaiting communication stream from container metrics...
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
