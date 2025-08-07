import React, { useEffect, useState } from "react";

export default function App() {
  const [dockerInfo, setDockerInfo] = useState({
    mode: "Detecting...",
    nodeName: "",
    nodeIP: "",
    containers: []
  });

  useEffect(() => {
    const fetchDockerInfo = async () => {
      const response = await fetch("/api/docker-info");
      const data = await response.json();
      setDockerInfo(data);
    };
    fetchDockerInfo();
  }, []);

  return (
    <div className="w-full h-screen bg-gray-100 p-6">
      <header className="text-4xl font-bold mb-6 text-center">Sample Docker App</header>
      <div className="grid gap-6 max-w-4xl mx-auto">
        <div className="bg-white shadow-xl rounded-xl p-6">
          <h2 className="text-2xl font-semibold mb-2">Docker Mode</h2>
          <p>{dockerInfo.mode}</p>
        </div>

        <div className="bg-white shadow-xl rounded-xl p-6">
          <h2 className="text-2xl font-semibold mb-2">Node Info</h2>
          <p><strong>Name:</strong> {dockerInfo.nodeName}</p>
          <p><strong>IP Address:</strong> {dockerInfo.nodeIP}</p>
        </div>

        <div className="bg-white shadow-xl rounded-xl p-6">
          <h2 className="text-2xl font-semibold mb-2">Containers</h2>
          {dockerInfo.containers.length > 0 ? (
            dockerInfo.containers.map((c, idx) => (
              <div key={idx}>
                <p><strong>Name:</strong> {c.name}</p>
                <p><strong>IP:</strong> {c.ip}</p>
              </div>
            ))
          ) : (
            <p>No containers running.</p>
          )}
        </div>
      </div>
    </div>
  );
}
