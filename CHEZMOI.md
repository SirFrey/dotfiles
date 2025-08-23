# How to use chezmoi

## Introduction
[chezmoi](https://chezmoi.io/) is a powerful and flexible tool for managing your dotfiles across multiple machines. It allows you to keep your configuration files in a single repository and apply them consistently wherever you go.

## Quick Commands

- **Initialize chezmoi**: 
  ```bash
  chezmoi init <repository-url>
  ```
  This command initializes chezmoi with your dotfiles repository.
- **Apply dotfiles**: 
  ```bash
  chezmoi apply
    ```
    This command applies your dotfiles to the current machine.
- **Add a file**:
    ```bash
    chezmoi add <file-path>
    ```
    This command adds a file to your dotfiles management.
- **Edit a file**:
    ```bash
    chezmoi edit <file-path>
    ```
    This command opens a file in your default editor for modification.
- **View status**:
    ```bash
    chezmoi status
    ```
    This command shows the status of your dotfiles.
- **Update chezmoi**:
    ```bash
    chezmoi update
    ```
    This command updates chezmoi to the latest version.
- **Remove a file**:
    ```bash
    chezmoi remove <file-path>
    ```
    This command removes a file from your dotfiles management.
- **Sync changes from local to chezmoi dotfiles manager**:
    ```bash
    chezmoi re-add
    ```

