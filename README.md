# DBless Ecommerce Website via WhatsApp

This project eliminates the need for a traditional database to simplify compliance with data regulations. 
Instead of storing customer data or order details in a database, all orders and interactions are tracked directly through WhatsApp. 
This approach reduces the complexity of managing sensitive data while leveraging WhatsApp as the primary communication and order-tracking platform.


## How It Works?
To host each language version of the site on separate subdomains using GitHub Pages, we maintain a dedicated repository for each language. These language repositories are added as submodules to the main site-generator repository. Shell scripts in the site-generator automate the process: they generate all language-specific sites and push updates to their respective submodule repositories.

## Data Files

The project uses two JSON files to manage data:

1. **site.json**: Contains site-specific configurations.
2. **product.json**: Stores product details.

After adding or updating data in these files, run the `update.sh` script. This script generates the necessary files required for the application to function correctly.

## Client JS Files

Under the `programmatic` folder, you will find JavaScript files responsible for enabling the basket and other functionalities of the application. 
These scripts ensure smooth operation and interaction for users.

When you run the `update.sh` script located in the `scripts` folder, it processes and updates all the necessary files, ensuring the application is ready to function with the latest configurations and data.

## Site Images for Pages & Products

All images for pages and products must follow a consistent naming convention and be placed in their respective folders:

- **Page Images**: Store images for pages under the `img/pages` folder.
- **Product Images**: Store product images under the `products` folder.

Ensure that the image filenames match the corresponding page or product names exactly to maintain consistency and avoid errors.
