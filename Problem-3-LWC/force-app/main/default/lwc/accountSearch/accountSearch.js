/**
 * @description Live Account Search LWC controller.
 *              Debounces user input (300 ms), calls Apex imperatively,
 *              manages loading / error / empty states, and navigates to
 *              Account records via NavigationMixin.
 * @author      Abhishek
 */
import { LightningElement, track } from 'lwc';
import { NavigationMixin }          from 'lightning/navigation';
import searchAccounts               from '@salesforce/apex/AccountSearchController.searchAccounts';

/** Debounce delay in milliseconds (meets the ≥ 300 ms requirement). */
const DEBOUNCE_DELAY = 300;

/** Currency formatter – matches the org's default USD display. */
const CURRENCY_FORMATTER = new Intl.NumberFormat('en-US', {
    style                : 'currency',
    currency             : 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
});

export default class AccountSearch extends NavigationMixin(LightningElement) {

    // ─────────────────────────────────────────────────────────────────────────
    // Reactive state
    // ─────────────────────────────────────────────────────────────────────────

    @track accounts     = [];
    @track isLoading    = false;
    @track hasError     = false;
    @track errorMessage = '';
    @track searchTerm   = '';

    /** Tracks whether the user has typed anything at all. */
    _hasSearched = false;
    /** Timer reference for the debounce. */
    _debounceTimer = null;

    // ─────────────────────────────────────────────────────────────────────────
    // Computed display flags
    // ─────────────────────────────────────────────────────────────────────────

    get showIdleState() {
        return !this._hasSearched && !this.isLoading && !this.hasError;
    }

    get showNoResults() {
        return (
            this._hasSearched     &&
            !this.isLoading       &&
            !this.hasError        &&
            this.accounts.length === 0
        );
    }

    get showTable() {
        return (
            !this.isLoading       &&
            !this.hasError        &&
            this.accounts.length > 0
        );
    }

    get resultCountLabel() {
        const count = this.accounts.length;
        if (count === 0) return '';
        return count === 50
            ? 'Showing first 50 results — refine your search to see fewer.'
            : `${count} account${count === 1 ? '' : 's'} found`;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Event handlers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Fires on every keystroke; debounces before triggering the Apex call.
     * @param {CustomEvent} event - change event from lightning-input
     */
    handleSearchChange(event) {
        this.searchTerm = event.target.value;

        // Clear any pending timer
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }

        // If the field is cleared, reset to the idle state immediately
        if (!this.searchTerm.trim()) {
            this._hasSearched = false;
            this.accounts     = [];
            this.hasError     = false;
            this.isLoading    = false;
            return;
        }

        // Show spinner right away so the UI feels responsive
        this.isLoading = true;

        // Schedule the Apex call after the debounce delay
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._debounceTimer = setTimeout(() => {
            this._fetchAccounts(this.searchTerm);
        }, DEBOUNCE_DELAY);
    }

    /**
     * Navigates to the clicked Account's record page.
     * @param {MouseEvent} event - click event from a table row
     */
    handleRowClick(event) {
        const accountId = event.currentTarget.dataset.id;
        if (!accountId) return;

        this[NavigationMixin.Navigate]({
            type      : 'standard__recordPage',
            attributes: {
                recordId  : accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    /**
     * Enables keyboard navigation (Enter / Space) on table rows.
     * @param {KeyboardEvent} event
     */
    handleRowKeypress(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleRowClick(event);
        }
    }

    /**
     * Prevents the row click handler from firing when the phone anchor
     * is clicked directly (so the tel: link can open natively).
     * @param {MouseEvent} event
     */
    handlePhoneClick(event) {
        event.stopPropagation();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private: Apex call
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Calls Apex imperatively and processes the result.
     * @param {string} term - the search keyword
     */
    _fetchAccounts(term) {
        this._hasSearched = true;
        this.hasError     = false;

        searchAccounts({ searchTerm: term })
            .then(data => {
                this.accounts  = this._enrichAccounts(data);
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading    = false;
                this.hasError     = true;
                this.accounts     = [];
                this.errorMessage = this._extractErrorMessage(error);
            });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private: data helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Adds derived display fields to each Account record so that the
     * template stays logic-free.
     * @param   {Object[]} records - raw Apex result
     * @returns {Object[]} enriched records
     */
    _enrichAccounts(records) {
        return records.map(acc => ({
            ...acc,
            formattedRevenue: acc.AnnualRevenue != null
                ? CURRENCY_FORMATTER.format(acc.AnnualRevenue)
                : '—',
            phoneHref: acc.Phone ? `tel:${acc.Phone}` : null
        }));
    }

    /**
     * Extracts a human-readable message from an Apex / network error.
     * @param   {Object} error
     * @returns {string}
     */
    _extractErrorMessage(error) {
        if (error && error.body) {
            if (Array.isArray(error.body) && error.body.length > 0) {
                return error.body[0].message;
            }
            if (typeof error.body.message === 'string') {
                return error.body.message;
            }
        }
        return 'An unexpected error occurred. Please try again.';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    disconnectedCallback() {
        // Clean up the debounce timer if the component is removed
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
    }
}
