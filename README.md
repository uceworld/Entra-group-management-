# Microsoft Graph Group Member and Owner Exporter

This PowerShell script fetches all Microsoft Entra groups, along with their members and owners, and exports the data into a CSV file. The script utilizes the Microsoft Graph API to retrieve information about groups, users, devices, and service principals in an organization.

## Description

This script is designed for administrators who need to extract and review the membership and ownership details of Microsoft 365 groups in their tenant. It fetches the following details:

- **Group Information**: Display name, group type (Microsoft 365 or Security), membership type (Dynamic or Assigned), and mail address.
- **Group Members and Owners**: For each group, it retrieves both members and owners, including their type (user, device, service principal), display names, and principal identifiers.

The data is exported to a CSV file for further analysis or reporting, and error handling ensures that any issues during the script execution are logged in a separate error log file.

## Features

- Fetches all groups from Microsoft Graph.
- Classifies groups into Microsoft 365 or Security based on their group type.
- Retrieves both group members and owners.
- Resolves details for each member/owner (user, device, group, service principal).
- Exports results to a CSV file.
- Logs errors to a separate file for review.

## Requirements

- PowerShell 7.x or later.
- Microsoft Graph PowerShell SDK (install via `Install-Module Microsoft.Graph`).
- Necessary permissions to access Microsoft Graph data (Group.Read.All, User.Read.All, Device.Read.All, Directory.Read.All).
- Internet connection to query the Microsoft Graph API.

## Usage

1. Open PowerShell as an administrator.
2. Ensure the Microsoft Graph SDK is installed. Run:
    ```powershell
    Install-Module Microsoft.Graph
    ```
3. Download or clone this repository to your local machine.
4. Run the script:
    ```powershell
    .\ExportGroupMembersAndOwners.ps1
    ```
    - The script will prompt for authentication if you're not already signed in to Microsoft Graph.
    - It will fetch groups, retrieve members and owners, and export the data to `AllGroupObjects3.csv`.
    - Errors encountered during the execution will be logged in `GroupExtractionErrors.txt`.

## Parameters

- **$outputFile**: The path where the CSV export file will be saved. Default is `AllGroupObjects3.csv`.
- **$errorLog**: The path for the error log file. Default is `GroupExtractionErrors.txt`.

## Example Output

The exported CSV file will contain the following columns:

- `GroupId`: Unique identifier for the group.
- `GroupDisplayName`: Name of the group.
- `Mail`: Email address of the group.
- `GroupType`: Type of the group (Microsoft 365 or Security).
- `MembershipType`: Membership type (Dynamic or Assigned).
- `Role`: Role of the object (Member or Owner).
- `ObjectId`: Unique identifier for the object (user, device, or service principal).
- `ObjectType`: Type of the object (user, device, service principal).
- `ObjectDisplayName`: Display name of the object.
- `ObjectIdentifier`: Principal name (email for users, device ID for devices, etc.).

## Error Handling

- The script logs any errors encountered during group retrieval, member/owner fetching, or resolving object details.
- All errors are written to `GroupExtractionErrors.txt` for review.

## Contributing

Contributions are welcome! If you find bugs, want to suggest enhancements, or improve the documentation, feel free to fork the repository and create a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
