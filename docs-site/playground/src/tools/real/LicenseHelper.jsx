import { useState, useMemo } from 'react';
import TerminalShell from '../../components/TerminalShell';
import CopyButton from '../../components/CopyButton';

function mit(year, name) {
  return `MIT License

Copyright (c) ${year} ${name}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.`;
}
function apache(year, name) {
  return `Apache License 2.0

Copyright ${year} ${name}

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.`;
}

export default function LicenseHelper() {
  const [type, setType] = useState('mit');
  const [name, setName] = useState('UtilityKit Contributors');
  const year = new Date().getFullYear();

  const text = useMemo(() => (type === 'mit' ? mit(year, name) : apache(year, name)), [type, name, year]);

  return (
    <TerminalShell
      title="license — License Helper"
      subtitle="_license_helper.sh"
      badge={{ label: 'Live', kind: 'live' }}
      footer="Generated with the current year, matching the CLI's --generate output exactly."
    >
      <div className="uk-row">
        <div className="uk-field">
          <label>Type</label>
          <select className="uk-select" value={type} onChange={(e) => setType(e.target.value)}>
            <option value="mit">mit</option>
            <option value="apache">apache</option>
          </select>
        </div>
        <div className="uk-field" style={{ flex: 2 }}>
          <label>Name</label>
          <input className="uk-input" value={name} onChange={(e) => setName(e.target.value)} />
        </div>
      </div>

      <div className="uk-out-box">
        <CopyButton text={text} />
        <pre className="uk-line" style={{ margin: 0, fontSize: 12, paddingRight: 60 }}>{text}</pre>
      </div>
    </TerminalShell>
  );
}
