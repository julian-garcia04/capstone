import React, { useState } from 'react';
import api from '../api'; // This uses the bridge we just built

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // This matches your PM's "1B. Login Page" requirement
      const response = await api.post('login/', { username, password });
      alert('Logged in successfully!');
      console.log(response.data);
    } catch (error) {
      alert('Login failed. Check your credentials.');
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h2>Athlete Login</h2>
      <form onSubmit={handleLogin}>
        <input
          type="text"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <br />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <br />
        <button type="submit">Login</button>
      </form>
    </div>
  );
};

export default Login;