# Azure AI Demo

## Overview

This project is a web application that allows users to chat with Azure Copilot. It includes a simple HTML interface and a PowerShell script for deployment.

## Prerequisites

- [Node.js](https://nodejs.org/) (version 14 or higher recommended)
- [npm](https://www.npmjs.com/) or [Yarn](https://yarnpkg.com/)
- [Parcel](https://parceljs.org/) (for building the project)

## Getting Started

### Installation

1. Clone the repository:

   ```
   git clone https://github.com/your-username/azure-ai-demo.git
   cd azure-ai-demo

   ```

2. Install the dependencies:

   ```
   npm install

   or

   yarn install

   ```

### Development

To start the development server, run:

    ```
    npm start

    or

    yarn start

    ```

This will start the Parcel development server and open your application in the default web browser.

Building for Production

To build the project for production, run:

```
npm run build

or

yarn build

```

This will create a dist directory with the bundled files.

### Deployment

You can deploy the contents of the dist directory to your web server or hosting service.

### Project Structure

- index.html - Main HTML file for the application
- css/styles.css - CSS styles for the application
- src/ - Source files for your application
- dist/ - Bundled output files (generated after running the build script)
- package.json - Project configuration and dependencies
- deploy.ps1 - PowerShell script for deployment

### Scripts

```
npm start / yarn start - Start the development server
npm run build / yarn build - Build the project for production
```

### HTML Structure

The index.html file includes the following sections:

- Toolbar: Contains the title and navigation links (Settings, Profile, Help).
- Content Container: Contains the navigation menu with links to different screens (Home, Documents).

Excerpt from index.html

```
<body class="flex-container">
    <div id="toolbar">
        <div class="title">Chat with Azure Copilot</div>
        <div class="links">
            <a href="#settings">Settings</a>
            <a href="#profile">Profile</a>
            <a href="#help">Help</a>
        </div>
    </div>
    <div id="content-container">
        <div id="nav-container">
            <nav>
                <ul>
                    <li>
                        <a href="?screen=home" class="nav-item">
                            <svg width="28" height="28" fill="currentColor" class="bi bi-house" focusable="false"
                                viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M0 0h24v24H0z" fill="none"></path>
                                <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"></path>
                            </svg>
                            Home
                        </a>
                    </li>
                    <li>
                        <a href="?screen=documents" class="nav-item">
                            Documents
                        </a>
                    </li>
                </ul>
            </nav>
        </div>
    </div>
</body>
```

### Contributing

Contributions are welcome! Please open an issue or submit a pull request.

### License

This project is licensed under the MIT License. See the LICENSE file for details.
