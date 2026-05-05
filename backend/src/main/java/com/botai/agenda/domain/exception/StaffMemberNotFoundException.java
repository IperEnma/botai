package com.botai.agenda.domain.exception;

import java.util.UUID;

public class StaffMemberNotFoundException extends AgendaDomainException {
    public StaffMemberNotFoundException(UUID id) {
        super("Staff member not found: " + id);
    }
}
