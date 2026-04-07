import React, { useState } from 'react';
import api from '../api';

const Register = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // Matches PM Task 1A: POST /register/
      await api.post('register/', { username, password });
      alert('Account created! Now try logging in.');
    } catch (error) {
      alert('Registration failed. Username might be taken.');
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h2>Create Athlete Account</h2>
      <form onSubmit={handleRegister}>
        <input type="text" placeholder="Username" onChange={(e) => setUsername(e.target.value)} /><br />
        <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} /><br />
        <button type="submit">Sign Up</button>
      </form>
    </div>
  );
};

export default Register;